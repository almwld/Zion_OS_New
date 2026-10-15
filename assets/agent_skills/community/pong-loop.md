---
name: pong-loop
description: >
  Two-paddle build loop. caveman-ponytail (minimal code, YAGNI) and caveman-bespoke
  (anticipatory code, YAGWNI) volley one coding task as scoped subagents while the
  main session referees with deterministic checks. Modes: tdd (bespoke serves failing
  tests, ponytail returns smallest passing code), rally (serial critique-and-revise),
  split (parallel independent builds, cross-review, merge). Use when the operator says
  "pong-loop", "pong", "ping-pong the two cavemen", "let ponytail and bespoke fight it
  out", "minimal vs future-proof", or wants a design pressure-tested from both
  directions before shipping. Do NOT use for trivial one-liners, hotfixes, or
  non-coding work.
version: 0.1.0
execution-mode: remedial
meta-skill: loop
meta-skill-mode: invocation-time
meta-skill-topology: loop
argument-hint: "[tdd|rally|split] <task> [max <volleys>] [to <points>]"
category: dev-tools
status: candidate
---

# Pong-Loop

Two paddles, one ball, one referee.

| Role | Skill | Bias | Scores when |
|------|-------|------|-------------|
| Left paddle **PONY** | `caveman-ponytail` | Smallest correct code. Deletion over addition. | Opponent ships code no check exercises, or code a repo rule forbids |
| Right paddle **BESP** | `caveman-bespoke` | Anticipate edge cases and future scenarios. | Opponent's code fails a check or misses a stated requirement |
| **Referee** | main session, normal prose | Neutral. Runs checks. Owns governance. | Never plays |

The ball is the artifact: a diff plus its test file. A shot changes the ball. A shot that changes nothing is a **let**.

## Context Gathering

- Detect platform: `python -c "import platform; print(platform.system())"`. Pick the project's own test command for that platform (`pytest`, `npm test`, `go test ./...`; on Windows run it from PowerShell).
- Read the task, the target code, and repo rules (`AGENTS.md`, `CLAUDE.md`, `operating-model.md`, `stdlib-only.md` where present) before the serve. Both paddles inherit these; neither may override them.
- Write down the requirement list R1..Rn from the operator's words. The referee judges against this list and only this list. Make each item exact: input types, character set, bounds. In the first live test R2 said "invalid input raises ValueError" and listed its cases. A real break, `'٥m'` returning 300 because `\d` matches Unicode digits, was then ruled out of bounds and deferred.

## Mode exclusivity

`caveman-bespoke` and `goldplate-ponytail` are mutually exclusive as *global* modes. Pong-loop does not blend modes: each persona runs only inside its own subagent. The main session stays in its current mode and referees.

## Modes

Default: `tdd` when the repo has a runnable test command, otherwise `split`. Use `rally` only on request; free-form serial critique is the mode most prone to agreement collapse.

### `tdd` — ping-pong pairing

Bespoke is good at cases and poor at restraint. Ponytail is the reverse. So:

1. **Serve (BESP):** writes up to 3 failing tests. Each test names the requirement it guards (`# R2`) or a future scenario (`# bespoke: <scenario>`).
2. **Line call (Referee):** runs the tests and confirms they fail for the stated reason. A test tied to no Rn and no operator-approved scenario is **out**; it moves to the deferred list and does not count.
3. **Return (PONY):** writes the smallest code that passes the in-bounds tests. It may add no abstraction the tests don't force.
4. **Line call (Referee):** runs the full suite. A failure scores for BESP. Code in the return that no test exercises (dead branch, unused parameter) is a fault: PONY replays the return with it removed; no point is awarded. Check with the project's coverage tool. Without one, in Python, use `trace.Trace(count=True)` around the test run and list the source lines that never executed. Don't trust `python -m trace --coverdir` with `-m unittest`: it can write no report at all, and a missing report reads like full coverage.
5. Swap the serve every 2 volleys: PONY serves a *deletion* ("these N lines are unneeded; suite stays green"), and BESP returns by proving a real case breaks (a new failing test) or concedes.

In this mode speculation survives only as a failing test the referee accepts. That settles the YAGNI-vs-YAGWNI dispute without a vote.

### `rally` — serial critique-and-revise

For design docs, APIs, or code without a test harness.

1. BESP drafts v0. (PONY serves instead with `rally pony-serve`.)
2. The other paddle returns **one shot**: a concrete edit plus at most 3 lines of reason. Pure critique with no edit is a let.
3. Alternate. Each paddle keeps its own context across volleys (continue the same subagent with `SendMessage`; do not respawn).

### `split` — parallel builds, cross-review, merge

For "which shape is right?" questions.

1. Spawn both paddles **in one message** as two `Agent` calls with `isolation: "worktree"`. Same task, same R-list, no view of each other.
2. When both finish, hand each paddle the other's diff. Each returns one shot: a failing test against the opponent, or a line-cited cut.
3. Referee runs every returned test against both builds and fills the scoreboard.
4. Merge: start from the build that passes more in-bounds checks with fewer lines. Port only the opponent's pieces that a passing test needs. Everything else goes to the deferred list.

## Referee procedure

### 0. **[MANDATORY]** Set bounds before the serve

State the mode, R-list, `max` volleys (default 4, hard ceiling 6), `to` points (default 3), and the check command. Unbounded rallies are prohibited. Published debate and self-refine results flatten after 2–4 rounds, so extra volleys mostly add cost.

### 1. Judge by checks, not rhetoric

Order of evidence: (1) test and lint results, (2) the R-list, (3) repo rules, (4) diff size. Persuasive prose is worth zero points. When the checks tie, smaller diff wins the point. Model judges favor longer answers, and BESP is always longer, so never award a point for completeness a check does not show.

When a judgment cannot come from a check (`rally`, `split` merge), judge twice with the two shots in swapped order and names stripped. If the two verdicts disagree, the point is a let.

### 2. Anti-collapse rules

- **No free concessions.** A paddle may concede only by citing the check that beat it. "Good point, agreed" without a check is a let and costs the conceding side the serve.
- **No persona drift.** If BESP starts deleting or PONY starts abstracting unprompted, the referee replays the volley once with the persona prompt restated. A second drift ends the match (`stop=drift`). The scheduled `tdd` serve swap is the only sanctioned role change.
- **No self-grading.** A paddle never judges its own shot.

### 3. Stop conditions (first to hit)

- a side reaches `to` points
- `max` volleys played
- 2 consecutive lets (convergence)
- the suite has been green and unchanged for 2 volleys
- a paddle proposes a protected-surface write, secret exposure, destructive command, or new dependency in a `stdlib-only` path. Stop immediately and report it; this is not a point.

### 4. Final output

```
PONG  <mode>  PONY <n> : <n> BESP   volleys=<k>  stop=<reason>  tokens=<total, per volley>
ball:      <files changed, +/- lines, test count, suite status>
kept:      <what shipped, one line each, winning side tagged>
deferred:  <out-of-bounds shots as "add when <trigger>">
repo-rule: <any rule that overruled a paddle, one line>
```

The shipped code carries `ponytail:` comments for deliberate ceilings and `bespoke:` comments only where a passing test exercises the hook.

## Subagent prompts

Each paddle's prompt must include: the persona skill name and intensity (`full`), the R-list, the current ball (path or diff), the last shot against it, and "Repo rules beat your persona; out-of-bounds shots go to deferred." Ask for output in this shape only: `shot: <edit|tests|concede>`, `diff:`, `why: <≤3 lines>`, `cites: <check or Rn>`.

Default to the parent model. Use a cheaper model for a paddle only when the operator asks.

## Cost

Minimum 2 subagents; `split` adds 2 cross-review turns. Default bounds (4 volleys) come to about 6 agent turns. The loop does not fit one-liners. If the first line call shows the task needs under 20 lines, stop and ship PONY's version.

Multi-agent debate often fails to beat a single agent sampled several times (Smit et al., ICML 2024). Do not claim the loop beat a single pass unless a single-pass baseline ran against the same checks.

## When NOT to use

- Hotfixes, trivial edits, one-off scripts
- Tasks with no verifiable check and no R-list (rally degenerates into debate)
- Security-boundary code where both paddles would be asked to trade away validation. Neither persona may simplify input validation, data-loss handling, or security controls.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `pong-loop tdd` | `review-pr` or `code-review` for a non-author check before commit |
| `pong-loop split` | `overengineering-audit` on the merged ball |
| deferred list non-empty | `decision-log` to record each "add when" trigger |
| repeated persona drift | `skill-evolve` on the drifting persona skill |

## Prior art

Research sweep 2026-09-13. No exact "pong-loop" match found. Nearby names: the PingPong role-play benchmark (Gusev 2024), the Ping-Pong AI builder/checker product, and "ping-pong loop" used as a failure-mode label for agents stuck replying to each other. Borrowed mechanics:

| Source | Taken |
|--------|-------|
| Ping-pong pair programming (XP) | `tdd` serve/return with failing tests |
| Multiagent Debate (Du et al. 2023, arXiv 2305.14325); MAD (Liang et al. 2023, arXiv 2305.19118) | round cap near 4; moderate, not total, opposition; referee can end the match early |
| Talk Isn't Always Cheap (arXiv 2509.05396) | no-free-concession rule against conformity |
| LLM-as-judge biases (Zheng et al. 2023, arXiv 2306.05685) | swapped-order, name-stripped judging; no length credit |
| CAMEL (Li et al. 2023, arXiv 2303.17760) | role-drift detection; stop on repeated empty turns |
| MetaGPT (arXiv 2308.00352); Anthropic "Building effective agents" evaluator-optimizer | pass artifacts (diff + tests), not chat; use only where a measurable check exists |
| AutoGen two-agent chat termination | explicit max volleys and stop reasons |
| Should we be going MAD? (Smit et al. 2024, arXiv 2311.17371) | baseline required before claiming a win |

## Related

- `caveman-ponytail`, `caveman-bespoke`: the paddles
- `goldplate-ponytail`, `goldplate-bespoke`: the other diagonal of the 2x2 matrix; not paddles in v0.1.0
- `dialectical-analysis`, `dual-agent`, `loop`: neighbouring multi-perspective and iteration patterns
