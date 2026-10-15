---
name: goal-selection
description: "Use this whenever the user says to pick/choose/select your own goal, find productive work, join the fleet, continue autonomously, take the next lane, or decide what to do after a goal completes. Turns live bus, repo, PR/CI, memory, and operator-context signals into one concrete, non-duplicative owned goal with acceptance criteria and bus receipts."
version: 0.2.0
execution-mode: side_effecting
argument-hint: "[quick|deep] [--read-only|--write-ok] [--forever]"
category: fleet-ops
status: candidate
providers:
  required: [pytest, python]
---
# Goal Selection

Select one useful goal when the operator delegates prioritization to the agent.

This skill exists because "pick a goal" is not the same as "brainstorm options."
The operator wants the fleet to move. A good selected goal is current, owned,
bounded, reviewable, and hard to confuse with another agent's lane.

## Trigger Context

Use this skill when the user says any variant of:

- "pick a goal"
- "choose your own goal"
- "find work"
- "join the fleet"
- "continue autonomously"
- "next goal"
- "do productive work"
- "what should this session do next?"

Also use it after completing a lane if the operator has established an ongoing
"keep choosing work" cadence.

## Goal Shape

Write the selected goal as one sentence:

```
<verb> <artifact/system> so that <fleet/operator outcome>, verified by <specific evidence>, without <explicit non-actions>.
```

Examples:

- `Review PR #905's handoff template so the fleet does not copy unsafe bus examples, verified by a GitHub/bus REVIEW, without editing files.`
- `Fix the skill validator's broken-link report so shared skill health is clean, verified by validate-skill-yaml and skill-health output, without touching unrelated skill rewrites.`
- `Triage the active CI blocker on PR #901 so stacked PRs can move, verified by failed-job logs and a bus STATUS, without rerunning expensive jobs unless needed.`

## Workflow

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=goal-selection] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Establish Authority and Mode

Classify the session before touching files:

- `read-only`: review, audit, triage, status, source verification.
- `write-ok`: operator has asked for implementation or the selected goal requires safe local edits.
- `consequential`: shared governance, CI, security, protected surfaces, external integrations, or broad repo changes.

If the task is consequential, plan for non-author review unless the operator
explicitly waived it.

If a formal goal-tracking tool is available and no active goal exists, create a
formal goal. If the tool already has a completed goal and refuses a new one,
continue with this workflow and record the chosen lane on the bus.

For continuous autonomous cycles, bind to the persistent goal harness:

- `python $HOME/.agents/scripts/goal-harness.py add "<goal text>" --agent <agent> ...`
- `python $HOME/.agents/scripts/goal-harness.py seed --agent <agent> --seed <file>`
- `python $HOME/.agents/scripts/goal-harness.py loop --agent <agent> --forever`
- Manual mode: `python $HOME/.agents/scripts/goal-harness.py select --agent <agent>` then `python ... complete --agent <agent> --goal-id ...`
- Auto mode (operator-on-loop only): `python $HOME/.agents/scripts/goal-harness.py loop --agent <agent> --auto --forever --operator-present`

**Operator-on-loop gate:** the persistent `loop --auto --forever` deployment requires an explicit `--operator-present` flag and must not be run unattended. If the operator is stepping away or the agent is alone, use `autoresearch-mode` instead — see `rules/goal-harness-operator-gate.md`.

Quick helper:

- `powershell -ExecutionPolicy Bypass -File $HOME/.agents/scripts/goal-cycle.ps1 -Agent <agent> -Auto -Forever`

Use this when the operator says “keep choosing work,” “next goal,” “do productive work,”
or similar requests for ongoing progression.

### 2. CRAB Check

Before claiming a lane, gather live state:

- Current directory and whether it is a git repo.
- Actual target repo/worktree branch and dirty status.
- Stashes in the target repo when edits might happen.
- Canonical bus status and last 20-80 entries.
- Active WIP lanes and direct requests to this agent.
- Open PRs/checks if the likely lane involves GitHub/Gitea.
- Relevant memory entries if prior context can prevent duplicate work or stale claims.

Prefer `rg`, `git`, `gh`, and the canonical bus writer/reader over memory-only
claims. Memory helps rank work; live state decides.

### 3. Build Candidate Lanes

Create 3-7 candidate goals from live signals. Good sources:

- Direct bus `PROPOSAL`, `QUESTION`, `BLOCKED`, `REVIEW`, or stale `WIP_START`.
- PRs needing non-author review, CI triage, or merge-readiness evidence.
- Recent failed checks where logs are available and no other lane owns the repair.
- Dirty shared worktrees that need classification before anyone touches them.
- Operator queue items that are agent-executable.
- Skill/rule validation failures with narrow blast radius.
- Recently completed work that needs verification, closeout, or follow-up.

Do not pick:

- A lane another agent already claimed unless you are explicitly reviewing it.
- Work blocked on credentials, UI-only operator decisions, or inaccessible artifacts.
- Broad cleanup in a dirty tree when a narrow useful slice exists.
- Expensive external API work unless the operator authorized spend.
- A task that requires direct push to `main`, force-push, secret handling, or hook bypass.

### 4. Score Candidates

Score each candidate quickly. Use judgment, but make the tradeoff explicit.

| Factor | High score means |
|---|---|
| Operator value | Unblocks Reuben, a PR stack, CI, runtime health, governance, or another agent. |
| Freshness | Based on current bus/PR/CI state, not old memory. |
| Non-duplication | No active lane already owns it. |
| Reversibility | Easy to back out or limited to read-only evidence. |
| Verifiability | Has a concrete command, PR comment, test, source check, or receipt. |
| Scope fit | Can be completed in this session without broad refactors. |

Default tie-breaker:

1. P0/P1 safety, CI, runtime, or governance blockers.
2. Non-author review for pending consequential work.
3. Narrow implementation that unblocks a validated queue item.
4. Validation or cleanup of shared skill/rule health.
5. Durable synthesis or handoff only when execution is blocked.

### 5. Claim One Goal

State the selected goal to the user in one or two sentences, then act. Do not
stop for approval unless the selected path is hard to reverse or outside the
operator's latest authorization.

For shared/fleet work, post a bus `WIP_START` before edits or external comments:

```
[lane=<domain>/<agent>/<slug>] host=<machine> target=<artifact> scope=<bounded scope>;
projects=<comma-list>; surfaces=<comma-list>; no_commit/no_push unless approved.
```

The `host=`/`target=` pattern is an older compact form still used by this skill; canonical
CRAB WIP_START fields (`repo=`, `branch=`, `head=`, `dirty_total=`, `stash=`, `next_owner=`,
`scope=`, `projects=`, `surfaces=`) should be used when the lane touches repo state.

Use the canonical sender identity for the current runtime. Do not invent a new
sender.

### 6. Define Done Before Acting

Write an internal acceptance checklist before implementation:

- Artifact inspected or changed.
- Validation command(s) run.
- Review/receipt posted if shared state changed.
- Dirty unrelated work preserved.
- Known gaps called out.

Keep the checklist small enough that it can finish in the current turn.

### 7. Execute the Lane

Act according to the chosen mode:

- For read-only reviews, inspect current artifact state, line references, and live checks.
- For edits, keep changes limited to the selected artifact(s); avoid generated churn unless required.
- For CI/debugging, verify with logs before proposing fixes.
- For source verification, use primary sources and exact links.
- For dirty worktrees, classify rather than normalize unrelated changes.

If you discover that the lane is already owned, invalid, or blocked, post a
`BLOCKED` or `STATUS` receipt and re-run candidate selection once.

### 8. Close the Loop

Before final response, post the appropriate bus closeout when shared state,
governance, code, PRs, runtime, or fleet coordination changed:

- `REVIEW` for peer-review verdicts.
- `WIP_END` for lanes you opened.
- `RECEIPT` for completed implementation or validation work.
- `BLOCKED` when the same artifact cannot be advanced without operator/external input.

Include:

- `artifact=`
- `artifact_state=`
- `proof_source=`
- `proof=`
- `next_owner=`
- `no_edits/no_commit` when applicable.

Final response should be short: selected goal, outcome, files changed, validation,
bus receipt, and remaining gap.

## Output Templates

### Goal Selection Summary

```
Selected goal: <one-sentence goal>
Why this one: <fresh signal + value + non-duplication>
Mode: read-only|write-ok|consequential
Done when: <evidence>
```

### Candidate Ranking

Use this only when the operator asks to approve/deny or when the choice is not
obvious:

```
1. <candidate> — value=<H/M/L>, freshness=<source>, conflict=<none/claimed>, done=<evidence>
2. <candidate> — ...

Pick: <selected candidate>
```

### Bus Closeout Skeleton

```
[lane=<domain>/<agent>/<slug>] host=<machine> artifact=<path|repo#pr|url>
artifact_state=<sha|branch|file hash|run id> proof_source=<command/API/query>
proof=<one-line result> result=<done|request_changes|blocked>
next_owner=<agent|operator|pr_author> no_commit/no_push
```

## Guardrails

- Do not claim leadership over other agents by default; select work, coordinate,
  and leave receipts.
- Do not treat stale heartbeat or memory summaries as current authority.
- Do not use goal selection to justify broad refactors.
- Do not make a commit unless the operator asked for one.
- Do not post `DECISION` or `DIRECTIVE` from an agent runtime.
- Do not skip bus receipts for shared/fleet work.

## Suggested Eval Prompts

See `evals/evals.json` for seed prompts. A good run should produce one concrete
goal, not a generic list, and should cite the live checks it would run before
acting.

For local regression checks, read `TESTING.md` and run
`scripts/grade_goal_selection.py --validate-suite` plus the unit tests under
`tests/`. The deterministic suite checks for the common failure modes: generic
option lists, missing live-state evidence, duplicate-lane risk, missing done
criteria, unsafe actions, and premature action when the operator asked to
approve or deny a ranked plan.

## Skill Chains

### Mandatory

None — goal selection reads live signals and proposes a goal; no upstream chain is required before proposing.

### Advisory

- After goal selected → `[scope-decompose]` if goal needs breakdown
- After goal selected → `[find-work]` to confirm no higher-priority work appeared
- After goal completes → `[goal-selection]` again if operator established ongoing cadence

## Authority

- **T1 (TRUSTED)**: Full access — select goal, claim lane, post WIP_START
- **T2 (Active/High)**: Full access — select goal, claim lane, post WIP_START
- **T3 (Medium)**: May run — select goal, operator confirms before claiming lane
- **T4 (Probationary)**: May run — advisory only, operator confirms before any action
- **Operator**: Override any restriction
