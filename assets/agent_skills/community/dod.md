---
name: dod
description: Definition of Done — per-task-type checklist enforcing what "complete" means. Soft gate before /commit /ship /pr-summary etc.
version: 0.1.1
execution-mode: advisory
argument-hint: "<task-type> [target]"
category: dev-tools
status: candidate
providers:
  required: [python]
---
# DOD — Definition of Done

Defines what "done" means for a task type, then runs the checklist against
a target. Soft gate: surfaces failures clearly, does NOT block downstream
skills. Operator decides whether to proceed.

## When to Use

- Before `[commit]` on any non-trivial change — confirm the task type's
  required checks pass
- Before `[ship]` to validate the broader pre-merge gate (DOD is upstream
  of `[ship-check]`)
- Before `[pr-summary]` to ensure the PR description can honestly claim done
- After any `[build]`, `[research]`, `[govern]` surge to verify the work
  meets the type's done bar
- During `[aar]` to attribute deviations to specific check failures

## Usage

```bash
[dod] feature                                    # mechanical checks against current state
[dod] research output/target.md               # research-artifact-specific checks against a file
[dod] paralegal-output output/target-readiness/99_audit/review-receipt.md   # paralegal-output checks against a HUMMBL review receipt
[dod] --list                                     # show available task types
[dod] research --show                            # show the DOD body for research without running
```

## Available task types

Registry lives in `~/.agents/skills/dod/registry/<task-type>.md`. Ship
with the operator-relevant set; add more by dropping new files in.

| Type | Used for |
|------|----------|
| `feature` | New code or functionality |
| `fix` | Bug fix |
| `doc` | Documentation change |
| `research` | Research artifact (memo, brief, comparison, intake) |
| `pr` | PR ready to merge |
| `deploy` | Deployment to a non-local environment |
| `governance-artifact` | HUMMBL governance overlay change (schema, control map, primitive) |
| `paralegal-output` | HUMMBL Paralegal output (chat reply, drafted doc, KB write) |
| `pilot` | Synthetic pilot run (corpus + harness + scorecard) |
| `skill` | Agent skill, rule, or guardrail change |

## How it works

Each task type has a registry file: `registry/<type>.md`. Format:

```markdown
---
type: <task-type>
description: <one-liner>
target_hint: <hint about what to pass as the optional second arg>
checks:
  - id: <stable id>
    label: <human readable>
    severity: required | recommended | optional
    type: command | attestation
    command: <shell command; $TARGET substituted with the second arg>
    expect_min: <integer>      # interpret stdout as int, require >= this
    expect_max: <integer>      # require <= this
    expect_match: <regex>      # stdout must match
    rationale: <only for type=attestation; explanation shown to operator>
---

# <Task type> DOD

<Markdown body explaining each check, the rationale, and off-ramps.>
```

For `type: command` checks, the runner shells out, captures stdout, and
applies the expectations. For `type: attestation` checks, the runner prints
the item as `[?] MANUAL` — operator confirms it manually (in a future
version, the runner can ask the operator directly).

## Soft gate semantics

- Required check FAIL → exit 1, runner prints `DOD: NOT MET`. Downstream
  skills ARE NOT auto-blocked. Operator chooses to proceed or remediate.
- Recommended check FAIL → exit 0, runner prints the failure. No gate effect.
- Optional check FAIL → exit 0, runner notes for awareness.
- Attestation check → always `MANUAL`; not counted as PASS or FAIL.

When operator proceeds despite a required failure, the override should be
recorded in the AAR or commit message ("DOD: required check `sources_cited`
failed; proceeding with operator override because [reason]"). The bus-receipt
chain is the audit trail.

## Adding a task type

```bash
cd ~/.agents/skills/dod/registry
cp research.md my-new-type.md
# Edit frontmatter + body
[dod] my-new-type --show   # verify the body parses
[dod] my-new-type <target> # run it
```

The registry file format is the spec; the runner is just a parser. New
task types require no code change.

## Limitations

- YAML-lite parser handles a subset of YAML: top-level scalars + `checks:`
  list of maps with scalar values. No nested objects in check definitions,
  no YAML anchors, no multi-line scalar literals.
- Double-quoted scalars support JSON-compatible escapes, including escaped
  quotes and backslashes; a whitespace-separated trailing comment is allowed.
  Single-quoted scalars preserve backslashes and decode doubled apostrophes.
  Invalid double-quoted values produce a registry error instead of running a
  malformed command. YAML-specific escape sequences outside the JSON subset
  are not supported.
- Commands run with `shell=True`; the registry file is trusted code. Don't
  install registry files from untrusted sources.
- `$TARGET` substitution is via the environment variable; commands needing
  more than one positional arg should pack them in `$TARGET` and split.
- No automatic gate enforcement on `[commit]` / `[ship]` / `[pr-summary]` —
  operator runs `[dod]` manually. v0.2 may add hook integration.

## Reference

- `~/.agents/skills/_index/SKILL.md` — full skill catalog
- `~/.agents/skill-routing.md` — auto-trigger patterns
- `~/.agents/skills/ship-check/SKILL.md` — downstream verifier; DOD is upstream
- `~/.agents/skills/aar/SKILL.md` — post-action review where DOD failures get recorded
