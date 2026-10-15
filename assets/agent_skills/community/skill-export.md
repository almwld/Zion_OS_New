---
name: skill-export
description: Export skills for other agents -- translate to Codex AGENTS.md, OpenClaw SOUL.md, or portable markdown.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[codex | openclaw | markdown | all] [SKILL_NAME or \"top20\"]"
category: hummbl-research
status: candidate
---
# Skill Export

Translate our Claude Code skills into formats usable by other agents in the fleet.

## When to Use
- Onboarding Codex to a new task area
- Configuring OpenClaw agent skills
- Creating portable documentation for any agent
- Sharing skills with the open-source community

## Formats

### codex
Export as AGENTS.md section (Codex convention):
```markdown
## Available Operations

### debug-test
When a test fails, isolate the root cause:
1. Reproduce with `python -m pytest <test> -v --tb=long`
2. Classify: assertion, import, fixture, environment, timeout, flaky
3. Check common causes: BUS_SIGNING_SECRET env, kill switch singleton, missing mock
4. Fix and verify: run single test, then full file

### ship-check
Before merging, verify:
1. `python -m pytest tests/ -q` -- all pass
2. No third-party imports in services/integrations/cognition/bus
3. No HIGH Bandit findings
4. No secrets in diff
```

### openclaw
Export as OpenClaw skill format (for ClawHub or local skills):
```markdown
---
name: debug-test
description: Isolate and fix a failing test
trigger: "test failure"
tools:
  - terminal
  - file
---
<skill body adapted for OpenClaw's tool calling conventions>
```

### markdown
Export as portable markdown (works with any agent that reads context files):
```markdown
# Operations Reference

## Testing
- Run tests: `python -m pytest tests/ -v`
- Debug failure: reproduce → classify → isolate → fix → verify
- Common causes: signing env, singleton leaks, missing mocks
...
```

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=skill-export] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Select skills to export
- `top20`: The 20 most-used skills (by bus/git evidence)
- `SKILL_NAME`: A specific skill
- `all`: Everything (warning: large output)

### 2. Read the skill
```bash
cat ~/.agents/skills/<name>/SKILL.md
```

### 3. Translate
Strip Claude Code-specific features:
- Remove `!`command`` DCI syntax (other agents can't execute it)
- Replace `[skill-name]` references with inline instructions
- Remove `## Live Context` sections
- Keep `## Execution` steps as the core content
- Adapt tool references (Claude's Edit/Read → generic file ops)

### 4. Write to target
- Codex: Append to `AGENTS.md` under `## Operations`
- OpenClaw: Write to `~/.openclaw/skills/<name>/`
- Markdown: Write to `docs/reference/agent-operations.md`

## Output Format
```
Skill Export | <format> | <scope>
═══════════════════════════════════

## Exported Skills
- <skill1>: <format> written to <path>
- <skill2>: ...

## Skipped (not translatable)
- <skill>: <reason> (e.g., requires Claude Code subagent spawning)
```

## Cross-Agent Skill Compatibility

| Feature | Claude Code | Codex | OpenClaw | Gemini CLI |
|---------|:-----------:|:-----:|:--------:|:----------:|
| SKILL.md format | Native | Via AGENTS.md | Via skills/ | Via GEMINI.md |
| DCI (`!`cmd``) | Yes | No | Yes (different syntax) | No |
| Tool calling | Built-in | Built-in | Via tools config | Built-in |
| Subagent spawning | Yes | No | Yes (sessions_spawn) | No |
| Bus access | Via bus_writer | Via bus_writer | Via gateway | Via bus_writer |

## Skill Chains

### Mandatory

None — file generation only (translates skills to Codex AGENTS.md, OpenClaw SOUL.md, portable markdown). No destructive pre-chain required.

### Advisory

- After `[skill-export]` → `[skill-test]` to validate exported skills in target agent context
- Before `[skill-export]` → `[skill-create]` if the skill to export doesn't exist yet
- After `[skill-export]` → `[decision-log]` to record which skills were exported and where

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (file generation only)
- **Operator**: Override any restriction
