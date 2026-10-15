---
name: self-discovery
description: >
  Teach any AI coding agent or sub-agent profile how to perform structured
  self-discovery: introspect its own runtime, model, permissions, profile,
  tools, skills, MCP servers, hooks, fleet context, and platform constraints.
  Invoke when an agent says "who am I", "what am I", "tell me about yourself",
  "self-discovery", "what can I do", "what model am I running on",
  "what are my capabilities", "introspect", "agent self discovery", or when a
  new session or subagent needs to understand its own envelope before starting
  work. Also invoke at session start for fleet agents that need to confirm
  their runtime envelope matches expectations.
version: 0.3.0
execution-mode: advisory
argument-hint: "[optional: profile or role name, e.g. 'researcher' or 'explorer']"
category: fleet-ops
status: candidate
---

# Agent Self-Discovery

You are an AI coding agent — a root session or a sub-agent — running inside
some runtime (Claude Code, Devin CLI, Codex, OpenCode, or another). This skill
teaches you to introspect
your own runtime envelope — who you are, what you can do, what constraints you
operate under, and where you fit in the fleet. Use this at session start, when
asked about yourself, or before starting work that requires knowing your own
capabilities.

## Why Self-Discovery Matters

Agents that don't know their own envelope make avoidable mistakes:

- A read-only subagent tries to edit a file and wastes a round-trip
- A Windows agent tries sandbox mode and hard-fails
- A free-tier model attempts a task that requires deep reasoning it can't provide
- A sub-agent doesn't know it can't spawn children and tries to dispatch one
- An agent doesn't know it has an MCP server available and misses a tool

Self-discovery is not navel-gazing — it is operational calibration. Know thyself
before you act.

## The Discovery Procedure

Follow these 8 steps in order. Each step has probe commands and reflection
questions. Adapt the commands to your platform (Windows = PowerShell,
Linux/macOS = bash). See `references/runtime-probe-commands.md` for the full
platform-safe command reference.

### Step 1: Identify Your Runtime

**What to discover:** CLI version, build commit, host machine, OS, and whether
you are the root agent or a subagent.

**Probe commands:**

```powershell
# Windows (PowerShell) — detect whichever agent CLI is present
foreach ($c in @('claude','devin','codex','opencode')) {
  if (Get-Command $c -EA SilentlyContinue) { "$c : $(& $c --version 2>$null | Select-Object -First 1)" }
}
$env:COMPUTERNAME
[System.Environment]::OSVersion.Version
# Note: OSVersion returns 10.0.x even on Windows 11 (e.g. 10.0.26200 = Win11 25H2).
# For an accurate marketing name, check build number: >=22000 is Windows 11.
```

```bash
# Linux/macOS — detect whichever agent CLI is present
for c in claude devin codex opencode; do
  command -v "$c" >/dev/null 2>&1 && echo "$c : $("$c" --version 2>/dev/null | head -1)"
done
hostname
uname -a
```

**Reflection questions:**
- Am I the root agent (I can dispatch sub-agents and ask the operator) or a
  subagent (I have a limited tool set)?
- If I'm a subagent, which profile am I running under? Check your system prompt
  for a profile name or persona description.
- What host am I on? Check the machine roster (`~/.agents/rules/machine-roster.md`)
  to understand my host's role in the fleet.

**Record:** `runtime: { version, commit, host, os, agent_type: root|subagent, profile: <name> }`

### Step 2: Identify Your Model

**What to discover:** Which AI model you're running on, its context window,
cost tier, and reasoning level support.

**Probe commands:**

```powershell
# Windows
devin models list 2>&1 | Select-String "GLM|glm|SWE|swe|adaptive|Adaptive|opus|sonnet|gpt|claude"
```

```bash
# Linux/macOS
devin models list 2>&1 | grep -iE "GLM|SWE|adaptive|opus|sonnet|gpt|claude"
```

Then check your config to see which model is selected:

```powershell
# Windows
cat "$env:APPDATA\devin\config.json" 2>&1 | Select-String "model"
```

```bash
# Linux/macOS
cat ~/.config/devin/config.json 2>/dev/null | grep model
# or
cat ~/.codeium/windsurf/config.json 2>/dev/null | grep model
```

**Reflection questions:**
- What model family and variant am I on? Read it from the system prompt or
  runtime config — do not assume a default.
- What is my context window size? (200K, 1M, etc.)
- Am I on a free tier or a paid tier? This affects how aggressively I should
  use tokens.
- Do I support configurable reasoning levels? (Alt+T to cycle)
- If I'm a sub-agent, which model am I using? Read-only explorer roles often
  use a cheaper default; general-purpose roles usually inherit the parent's
  model; custom profiles use their own `model:` field.

**Record:** `model: { family, variant, context_window, cost_tier, reasoning_levels, source: config|inherited|pinned }`

### Step 3: Identify Your Permission Mode

**What to discover:** Which permission mode you're in and what auto-approves vs
what prompts.

**How to check:** Look at your system prompt for the active mode. If you're
the root agent, the user can switch modes with `/mode`. If you're a subagent,
you inherit the session's mode but may have additional tool restrictions from
your profile.

**The 5 permission modes:**

| Mode | Read-only | Shell | Edits | High-risk |
|------|-----------|-------|-------|-----------|
| Normal | Auto | Prompt | Prompt | Prompt |
| Accept Edits | Auto | Prompt | Auto (workspace) | Prompt |
| Smart | Auto | Auto when safe | Auto (workspace) | Always prompt |
| Bypass | Auto | Auto | Auto | Auto |
| Autonomous (sandbox) | Auto | Auto (sandboxed) | Prompt | Auto (sandboxed) |

**Reflection questions:**
- What mode am I in? Can I tell from my system prompt?
- What permissions are pre-approved in the config? Check `permissions.allow`,
  `permissions.deny`, `permissions.ask` in the config file.
- If I'm a subagent, am I foreground (can prompt for approvals) or background
  (unapproved tools auto-denied)?
- Am I on Windows? If so, sandbox/autonomous mode is NOT available — it
  hard-fails. This is a platform constraint, not a config issue.

**Record:** `permissions: { mode, pre_approved: [...], denied: [...], asked: [...], platform_sandbox_available: true|false }`

### Step 4: Identify Your Agent Mode

**What to discover:** Which agent mode you're in (Normal, Plan, Ask) — this is
orthogonal to permission mode.

**The 3 agent modes:**

| Mode | Behavior | How to enter |
|------|----------|-------------|
| Normal | Full autonomy, all tools | `/normal` (default) |
| Plan | No edits, no exec — explore and plan only | `/plan` |
| Ask | No edits, no exec — read-only questions | `/ask <question>` |

**Reflection questions:**
- Am I in Plan mode? If so, I cannot make changes — I can only explore and
  present a plan for approval.
- Am I in Ask mode? If so, I can only answer questions with read-only tools.
- If I'm a subagent, I'm always in Normal mode — Plan and Ask are root-agent
  only.

**Record:** `agent_mode: normal|plan|ask`

### Step 5: Identify Your Tools and Capabilities

**What to discover:** What tools you have access to, what's restricted, and
what capabilities you have that you haven't used.

**How to check:** Look at your tool list in the system prompt. If you're a
subagent, your profile's `allowed-tools` field restricts what you can use.

**Core capability inventory.** Check each against your own tool list. Tool
*names* differ per runtime — the capability is what matters.

| Capability | Typical root agent | Read-only sub-agent | General sub-agent |
|---|---|---|---|
| Read files | Yes | Yes | Yes |
| Search / glob | Yes | Yes | Yes |
| Write / edit files | Yes | No | Yes (foreground) |
| Execute shell | Yes | No | Yes (foreground) |
| Web search | Yes | Yes | Yes |
| Web fetch | Yes | No | Yes (foreground) |
| Dispatch sub-agents | Yes | No | Only if nesting allowed |
| Collect sub-agent result | Yes | No | Only if nesting allowed |
| Ask the operator | Yes | No | No |
| Invoke skills | Yes | Yes | Yes |
| List MCP servers / tools | Yes | Yes | Yes |
| Call MCP tools | Yes | No | Yes (foreground) |
| Notebook read / edit | Yes | No | Yes (foreground) |

For the concrete tool names your runtime binds these to, see the runtime
binding table in `rules/skill-provider-neutrality.md`. Devin CLI's exact
per-profile matrix is in `references/profile-discovery-guide.md`.

**Reflection questions:**
- Can I edit files? If not, I'm read-only — don't attempt writes.
- Can I run shell commands? If not, I can't do `git status`, `git diff`, or
  any validation commands.
- Can I spawn subagents? If not (most subagents), I must do everything myself.
- Can I ask the user questions? If not (all subagents), I must complete my
  task autonomously without clarification.
- Do I have MCP tools? Check `mcp_list_servers` and `mcp_list_tools`.
- What capabilities do I have that I haven't used? (browser preview, notebook
  editing, cloud handoff, etc.)

**Record:** `tools: { core: [...], mcp: [...], restricted: [...], unused: [...] }`

### Step 6: Identify Your Skills, Rules, and Hooks

**What to discover:** What skills are available, what rules are always-on, and
what hooks fire on your actions.

**Probe commands:**

```powershell
# Windows
devin rules list 2>&1
devin skills list 2>&1 | Select-Object -First 30
```

```bash
# Linux/macOS
devin rules list 2>&1
devin skills list 2>&1 | head -30
```

**Reflection questions:**
- What rules are always-on? These shape my behavior every turn — I should know
  what they say.
- What skills are available? The system prompt lists them with trigger
  descriptions. I should invoke matching skills at session start.
- Are there hooks configured? Hooks can block my actions or inject context.
  Check `.devin/hooks.v1.json` or `~/.config/devin/config.json` for hooks.
- If I'm a subagent, do I have access to skills? Skills are loaded at session
  level, so yes — but I may not have the tools to invoke all of them.

**Record:** `extensibility: { rules: [...], skills_count: N, hooks: [...], plugins: [...] }`

### Step 7: Identify Your Fleet Context

**What to discover:** Where you fit in the multi-agent fleet, who your peers
are, and how you coordinate.

**How to check:** Read the machine roster at `~/.agents/rules/machine-roster.md`
and any AGENTS.md files in your working directory. Check for a coordination
bus (look for `bus-post.ps1` or a bus skill).

**Reflection questions:**
- What host am I on? What other agents are on my host?
- Is there a coordination bus? If so, what's my agent identity on the bus?
- Who are my fleet peers? (codex, claude-code, hermes, apex, opencode, etc.)
- What's my role in the fleet? (documentation, infrastructure, security,
  protocol expertise, canonical authority, embedded, etc.)
- Can I hand off to cloud Devin? (`/handoff` — only root agent)
- Do I have SSH access to other machines? Check for SSH config entries.

**Record:** `fleet: { host, role, peers: [...], bus: true|false, ssh_targets: [...] }`

### Step 8: Identify Your Platform Constraints

**What to discover:** What you CAN'T do because of your platform, model, or
configuration — not what you choose not to do.

**Platform constraint matrix:**

| Capability | Windows | Linux | macOS |
|-----------|---------|-------|-------|
| Sandbox mode | NOT available (hard-fail) | bwrap + seccomp | seatbelt |
| Shell env inheritance | No (PowerShell) | Yes (.bashrc/.zshrc) | Yes |
| `rm -rf` | Different syntax | Standard | Standard |
| `/dev/null` | Use `NUL` | Standard | Standard |
| `~` in paths | Use `$HOME` or `$env:USERPROFILE` | Standard | Standard |
| `grep`/`sed`/`awk` | Use Select-String or install | Standard | Standard |
| `date -u` | Use `Get-Date -Format` | Standard | Standard |
| `pgrep`/`pkill` | Use `Get-Process` | Standard | Standard |

**Model constraint reflection:**
- Am I on a free tier? I should be token-efficient.
- Is my context window limited (200K vs 1M)? I should `/compact` when needed.
- Do I support reasoning levels? If not, I can't "think harder" on demand.
- Am I a subagent with `max-nesting: 0`? I can't spawn children.

**Record:** `constraints: { platform: [...], model: [...], profile: [...] }`

## Producing the Self-Discovery Report

After completing all 8 steps, produce a structured report. The format depends
on who's asking:

### For the operator (human-readable)

```markdown
# Self-Discovery Report

## Runtime
- CLI version: v3000.4.25 (commit 7e8e528a)
- Host: NODE_ALPHA (Windows)
- Agent type: root | subagent (profile: <name>)

## Model
- Family: <model family and variant>
- Context: 200K
- Cost: Free tier
- Reasoning levels: <levels this model supports, or 'none'>

## Permissions
- Mode: Normal
- Pre-approved: [list]
- Sandbox available: No (Windows)

## Agent Mode
- Mode: Normal (full autonomy)

## Tools
- Core: read, write, edit, shell-exec, search, file-search, web-search, web-fetch, ...
- MCP: github (server-github)
- Restricted: none
- Unused: browser preview, notebook edit, cloud handoff

## Extensibility
- Rules: AGENTS (project), global_rules (Windsurf)
- Skills: [run `devin skills list` to count — do not guess]
- Hooks: [check .devin/hooks.v1.json and config — do not assume "none"]
- Plugins: [list if any]

## Fleet Context
- Host=node-alpha
- Role: [your role]
- Peers: codex, claude-code, hermes, apex, opencode
- Bus: Yes (coordination bus available)
- SSH: workstation

## Constraints
- Platform: No sandbox, PowerShell not bash, no /dev/null
- Model: Free tier, 200K context
- Profile: [if subagent, list tool/nesting restrictions]

## What I'm Good At
- [3-5 strengths based on profile and model]

## What I Struggle With
- [3-5 limitations based on profile, model, and platform]

## What I Should Use More
- [2-3 capabilities I have but haven't been using]
```

### For the bus (machine-readable summary)

```
host=<host> SELF-DISCOVERY: agent=<profile|root> model=<family> mode=<permission_mode> tools=<count> mcp=<servers> skills=<count> constraints=<platform|model|profile> fleet_role=<role> intel_type=TOPOINT
```

### For a subagent returning to its parent

```
Self-discovery complete. I am <profile> running on <model> with <tool_count> tools.
Key constraints: <top 2-3 constraints>. Ready for task assignment.
```

## Profile-Specific Discovery

Different profiles have different introspection needs. See
`references/profile-discovery-guide.md` for per-profile discovery questions
covering all 12 devin-* profiles and both built-in subagent profiles.

## When to Re-Run Self-Discovery

- **Session start**: Confirm your envelope matches expectations
- **After model switch**: `/model opus` changes your capabilities
- **After mode switch**: `/mode plan` changes what you can do
- **After config change**: New permissions, MCP servers, or hooks
- **After upgrade**: `devin update` may add features or change behavior
- **When something fails unexpectedly**: You may have hit a constraint you
  didn't know about
- **When asked**: "Who are you?" / "What can you do?" / "Tell me about yourself"

## Anti-Patterns

- **Don't skip steps**: Each step discovers something different. Skipping step 3
  (permissions) means you might try an action that will be denied.
- **Don't guess**: Run the probe commands. Reading the config file is more
  reliable than assuming.
- **Don't skip reflection**: The probe commands give you data; the reflection
  questions turn data into self-knowledge.
- **Don't skip constraints**: Knowing what you CAN'T do is as important as
  knowing what you can.
- **Don't make it long**: The report should be concise. If the operator wants
  detail, they'll ask. The bus summary should be one line.

## Read-Only Discovery Mode (for subagents without exec)

If you are a read-only sub-agent profile without shell-execution
access, you cannot run shell commands. Use these approaches instead:

### System prompt inspection (primary method)

Your system prompt contains most of what you need:
- **Tool list**: The tools section of your system prompt lists every tool you
  have. If `exec` is not listed, you don't have it. If `write` is not listed,
  you can't write files.
- **Mode indicators**: Look for "Full autonomy" (Normal), "Do NOT make changes"
  (Plan), or "read-only" (Ask).
- **Profile name**: Some subagent profiles include a persona description or
  profile name in the system prompt.
- **Model hints**: The system prompt may mention the model family (e.g., "You
  are powered by <model>").

### File reading (secondary method)

Use your read and filename-search tools to discover:
- **Config**: Read `%APPDATA%\devin\config.json` (Windows) or
  `~/.config/devin/config.json` (Linux/macOS) for model, permissions, MCP
- **Machine roster**: Read `~/.agents/rules/machine-roster.md` for fleet context
- **Your profile**: Read `~/.config/devin/agents/<name>.md` or
  `%APPDATA%\devin\agents\<name>.md` for custom profile definitions
- **Skills count**: Search for filename pattern `**/SKILL.md` under
  `~/.agents/skills/` (Windows: `%USERPROFILE%\.agents\skills\`)
- **AGENTS.md**: Search for filename pattern `**/AGENTS.md` from
  project root

### What you cannot discover without exec

- Exact CLI version (`<runtime> --version`)
- Exact model resolved at runtime (`devin models list`)
- Live rules list (`devin rules list`)
- Live MCP tools (`mcp_list_tools` — this is a tool, not a command, but may not
  be available to all subagent profiles)
- Available memory / system resources
- Running processes

Mark these as "Unknown (no exec)" in your report. Do not guess.

### Subagent report template (for profiles without exec)

```markdown
# Self-Discovery Report

## Runtime
- CLI version: Unknown (no exec)
- Host: <from machine roster or config path>
- Agent type: subagent (profile: <name>)

## Model
- Family: <from config or "Unknown">
- Context: <from config or "Unknown">
- Cost: <from config or "Unknown">

## Permissions
- Mode: <from system prompt or "Unknown">
- Pre-approved: <from config file>
- Sandbox available: <platform-dependent>

## Tools
- Core: <list from system prompt>
- Restricted: <list tools NOT in system prompt>
- MCP: <from config file>

## Fleet Context
- Host: <from machine roster>
- Peers: <from machine roster>
- Bus: <from AGENTS.md>

## Constraints
- Platform: <from path patterns in config>
- Profile: <from profile definition or system prompt>

## Unknowns (require exec)
- CLI version, exact model, live rules, live MCP tools, system resources
```

## What to Do When You Can't Complete a Step

If you hit a limitation during self-discovery:

1. **Note the limitation**: Record which step was incomplete and why
2. **Use alternative sources**: Try file reading, system prompt inspection, or
   web search before giving up
3. **Make reasonable assumptions**: If the config names a model, assume it
   even if you can't run the runtime's model-list command to confirm
4. **Document uncertainty**: Mark inferred values with `[inferred]` and unknown
   values with "Unknown"
5. **Don't fabricate**: Never make up a version number, model name, or count
6. **Report the gap**: Include a "Unknowns" section in your report listing what
   you couldn't discover and why

## Foreground vs Background Detection (for subagents)

If you are a subagent, you need to know whether you're foreground or background:

- **Foreground**: You can see this in your system prompt or tool behavior. If
  you attempt a tool that isn't pre-approved and get a prompt for approval,
  you're foreground. If the tool is auto-denied, you're background.
- **Background**: Unapproved tools are silently denied. You won't get a prompt.
  If you try a tool and it fails without explanation, you may be background.
- **Heuristic**: If your task description says "background" or "is_background:
  true", you're background. If it says "foreground" or doesn't specify, you may
  be either — test by attempting a non-pre-approved tool.
- **Practical impact**: If background, stick to pre-approved tools only. Don't
  attempt tools that require approval — they'll fail silently and waste your
  turn.

## Skill Chains
- For free-tier models for agent self-discovery probes -> `[reasoning-router]` (`route`)
- For discover opencode as a peer runtime via the bridge -> `[cross-runtime-bridge]` (`sessions`)
