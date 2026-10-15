---
provider-specific: true
name: devin-cli-runtime
description: Complete Devin CLI runtime reference for agents — permission modes, agent modes, subagents, skills, rules, plugins, MCP, sandbox, ACP, model selection, slash commands, keybindings, and optimization patterns. Invoke when you need to understand the full surface area of the CLI you're running in.
argument-hint: "[optional: section name like 'subagents' or 'modes']"
version: 1.0.0
execution-mode: advisory
triggers:
  - you need to understand the full surface area of the CLI you're running in
status: imported
provenance:
  source_surface: canonical
  original_version: 1.0.0
  import_date: 2026-08-10
category: fleet-ops
---
# Devin CLI Runtime Guide

You are running inside Devin CLI. This skill is the complete reference for your runtime. Use it to understand what modes are available, how subagents work, how to optimize cost, and what tricks the CLI supports.

**Current version:** v3000.3.27 (August 2026). Verify with `devin version`.

## Table of Contents

1. [Permission Modes](#permission-modes)
2. [Agent Modes](#agent-modes)
3. [Subagents](#subagents)
4. [Model Selection](#model-selection)
5. [Skills System](#skills-system)
6. [Rules System](#rules-system)
7. [Plugins](#plugins)
8. [MCP Servers](#mcp-servers)
9. [Sandbox](#sandbox)
10. [ACP (Agent Client Protocol)](#acp-agent-client-protocol)
11. [Slash Commands](#slash-commands)
12. [Keybindings](#keybindings)
13. [Session Management](#session-management)
14. [Optimization Patterns](#optimization-patterns)
15. [Profile Matrix](#profile-matrix)
16. [Profile Selection Guide](#profile-selection-guide)

---

## Permission Modes

Five permission modes control what auto-approves vs what prompts. Switch with `/mode <name>`, Shift+Tab to cycle, or `--permission-mode <name>` at launch.

### Behavior Matrix

| Tool type | Normal | Accept Edits | Smart | Bypass | Autonomous (sandbox) |
|-----------|--------|--------------|-------|--------|---------------------|
| Read-only (read, grep, glob) | Auto | Auto | Auto | Auto | Auto |
| Fetch (HTTP) | Prompt | Prompt | Auto when judged safe | Auto | Auto |
| Shell commands | Prompt | Prompt | Auto when judged safe | Auto | Auto (sandboxed) |
| File edits (edit/write) | Prompt | Auto (workspace) | Auto (workspace) | Auto | Prompt |
| High-risk (installs, mutating git, rm, sudo) | Prompt | Prompt | **Always prompt** | Auto | Auto (sandboxed) |

### Mode Details

**Normal** (default): Read-only auto-approves within current directory. Writes and shell commands prompt. Best for careful, interactive work.

**Accept Edits** (`/accept-edits`): Workspace file edits auto-approve. Shell commands and out-of-workspace writes still prompt. The expected default for most coding work.

**Smart** (`/smart`): Workspace edits auto-approve like Accept Edits. For everything else (shell, fetch, MCP tools, out-of-workspace writes), a fast model judges whether the action is safe to auto-run. If clearly safe → auto. If uncertain or unsafe → prompts as normal.

Smart mode NEVER auto-approves these categories, regardless of the model's judgment:
- Package installs (`npm install`, `pip install`, `cargo install`, `brew install`, ...)
- Mutating `git` operations (read-only subcommands like `git status` are still eligible)
- `rm`, `sudo`, and other destructive or privilege-escalating commands
- `kubectl delete` and destructive cloud CLI operations (`aws`, `gcloud`, `az`, `terraform`, ...)
- Anything that reads or writes dotenv files, key material, Git config, or agent configuration

Smart mode is rolling out gradually — off unless the server-side rollout flag is enabled for your account.

**Bypass** (`/bypass`, aliases `/yolo`, `/dangerous`): All tool calls auto-approved without prompting. Use only when you trust the agent with your whole machine. NEVER overrides org-level deny/ask rules.

**Autonomous**: Only available with `--sandbox` flag. Shell commands and fetches auto-approve because the OS-level sandbox enforces filesystem and network boundaries. Direct file edits via `edit`/`write` still prompt (they run inside the CLI process, not the sandbox). Granting a `Write(...)` scope mid-session dynamically expands the sandbox. This is the ONLY permission mode available in sandbox sessions — Normal/Accept Edits/Smart/Bypass are hidden.

### Precedence

1. **Deny rules** — checked first, always block
2. **Ask rules** — checked second, always prompt (overrides allow)
3. **Allow rules** — checked third, auto-approve
4. **Default** — no rule matches → prompt (or auto in bypass/autonomous)

Organization-level deny and ask rules ALWAYS take priority over the user's permission mode, including Bypass.

### Permission Configuration

```json
// .devin/config.json (project) or ~/.config/devin/config.json (user)
{
  "permissions": {
    "allow": ["Read(src/**)", "Exec(npm run)"],
    "deny": ["Exec(rm)"],
    "ask": ["Write(.env*)"]
  }
}
```

Local override: `.devin/config.local.json` (not committed to git).

**Scope matchers:**
- `Read(glob)` — file read access
- `Write(glob)` — file write access
- `Exec(cmd)` — shell command access (scoped to program runner: `uv run ruff` not broad `uv run`)
- `Fetch(url-pattern)` — HTTP fetch access
- `WebSearch(query)` — web search access
- `MCP(server:tool)` — MCP tool access

Recursive globs (`Read(/etc/**)`) now also cover the base directory itself.

---

## Agent Modes

Three agent modes control the agent's behavior posture. These are orthogonal to permission modes.

### Normal (default)
Full autonomy to use all tools freely. Exploring, writing, editing, running commands — all allowed (subject to permission mode).

### Plan (`/plan`)
- No edits, no shell commands — explore and plan only
- Read-only MCP tools (those annotated `readOnlyHint: true`) ARE allowed for context gathering
- Listing MCP servers, tools, and resources is allowed
- The agent creates a plan, presents it, and waits for approval before making changes
- **Megaplan keywords**: saying `megaplan`, `ultraplan`, or `masterplan` in plan mode triggers extra planning guidance — the agent plans more extensively and always asks at least one clarifying question before writing the plan
- Exiting plan mode injects an explicit mode-change announcement so the agent reliably starts acting in the new mode (fixes the bug where agents continued following plan-mode restrictions)

### Ask (`/ask <question>`)
- No edits, no exec — read-only tools only
- Read-only MCP tools allowed
- For questions and lookups, not work
- Onesgot: if you need to answer a question that requires shell execution, ask the operator to switch to Normal mode

### Switching
- `/mode` — show current mode
- `/mode <name>` — switch to named mode
- `/normal`, `/plan`, `/ask` — direct shortcuts
- Permission mode and agent mode are independent — you can be in Plan agent-mode with Smart permission-mode

---

## Subagents

Subagents are independent worker agents spawned by the parent. They share tools and codebase context but NOT conversation history. Each runs in its own context window.

### Built-in Profiles

| Profile | Tools | Model | Cost |
|---------|-------|-------|------|
| `subagent_general` | Full tools (fg) or pre-approved only (bg) | Same as parent agent | Same rate as parent — free on this fleet (GLM-5.2 High), expensive on premium parents |
| ~~`subagent_explore`~~ | — | — | **WITHDRAWN 2026-09-05** — dispatching it is denied by `subagent-guard.js`; see `rules/devin-subagent-profile-policy.md` |

**Fleet policy (hard rule)**: every `run_subagent` dispatch uses `profile="subagent_general"`. No exceptions without explicit operator approval — `rules/devin-subagent-profile-policy.md`. Read-only or persona behavior goes in the task prompt, not the profile. The guard hook also blocks named persona profiles (paid/quota-limited models).

**Cost note**: `subagent_general` inherits the parent's model. On this fleet the parent runs GLM-5.2 High (free), so general subagents are free. If an operator runs a premium parent (Opus, etc.), every general subagent runs on that model with its own context window — the profile stays `subagent_general` regardless; manage cost via fewer/smaller dispatches, not by switching profiles.

### Foreground vs Background

**Foreground**: Runs inline. Parent pauses and waits. You approve/deny tool calls as they come up. The prompt names the subagent requesting the action. Ctrl+B to background mid-run. Ctrl+C or Esc to cancel.

**Background**: Runs in parallel. Parent continues working. You're notified when it completes. Unapproved tools are AUTO-DENIED (background subagents cannot prompt for new permissions). They inherit only permissions already granted during the session.

**If a background subagent fails because a tool was denied**: resume it in the foreground to approve the necessary permissions.

### Interrupting

Interrupting the parent agent PARKS running subagents — it does NOT kill them. They park with state intact and resume on your next message. Subagent activity also survives a session reload.

### Cancelling

1. Subagent panel → press `x` on a running subagent
2. Foreground subagent → Ctrl+C or Esc

### Resuming

Cancelled, failed, or completed subagents can be resumed with a new prompt. Resumed subagents ALWAYS run in the foreground (so you can approve previously-denied tools). Useful for:
- Background subagent that failed on a denied tool → resume in foreground to grant
- Completed subagent that needs follow-up work
- Cancelled subagent that should continue

### Nesting Depth

By default, subagents CANNOT spawn their own subagents — only the root agent can. The `run_subagent` and `read_subagent` tools are disabled inside subagents.

Custom profiles can opt in via `max-nesting` frontmatter field:
- `max-nesting: 3` allows Root → Custom (depth 1) → Child (depth 2) → Grandchild (depth 3, cannot spawn)

**Warning**: Nested subagents multiply cost. Each level spawns additional agents with their own context windows. Use deliberately.

### Custom Subagents

Define custom profiles as markdown files:

**Locations:**
- Project: `.devin/agents/<name>.md` or `.agents/agents/<name>.md`
- Global: `%APPDATA%\devin\agents\` (Windows) or `~/.config/devin/agents/` (macOS/Linux)
- Also imported from Claude Code: `.claude/agents/*.md`

**Layout:** Flat file (`agents/<name>.md`) or directory (`agents/<name>/AGENT.md`)

**Frontmatter:**
```yaml
---
name: reviewer          # override path-derived identifier
description: Reviews code changes for correctness and style
model: sonnet           # pin a model (cheaper than parent if desired)
allowed-tools:          # restrict tools (cannot grant ask_user_question)
  - read
  - grep
  - glob
  - exec
max-nesting: 2          # allow this subagent to spawn children
---
```

The `model` field is the ONLY way to run a write-capable subagent on a model other than the parent's. Use it to pin a cheaper model for write work.

The agent sees custom profiles alongside built-ins and chooses the most appropriate. You can also ask for a specific profile by name ("review this using the reviewer subagent").

### Monitoring

- **Subagent indicator**: appears below input when background subagents run. Press ↓ from input, then Enter to open the subagent panel.
- **Subagent panel**: shows profile, title, status, elapsed time, tool call count for each subagent. Press `f` to foreground a background subagent. Press `x` to cancel.

### Enabling/Disabling

```json
// config.json
{ "subagents_enabled": false }
```
Removes `run_subagent` and `read_subagent` tools. Change applies live to running session. Org policy ("Default subagent model: None") overrides this.

---

## Model Selection

### Available Models (37 families)

Run `devin models list` for the full, current list. Major families:

| Family | Alias | Context | Cost (In/Out per MTok) |
|--------|-------|---------|----------------------|
| Claude Opus 5 | `opus` | 1M | $5 / $25 |
| Claude Fable 5 | — | 1M | $10 / $50 |
| Claude Sonnet 5 | `sonnet`, `claude` | 1M | $2 / $10 |
| GPT-5.6 Sol | — | 1M | $5 / $30 |
| GPT-5.6 Luna | — | 1M | $0.2 / $1.2 |
| GLM-5.2 | — | 200K | Free |

Each family has reasoning levels: `none`, `low`, `medium`, `high`, `xhigh`, `max`. Higher reasoning = more thinking tokens = more cost. Fast variants (`-priority` suffix) cost 2x but run faster.

### Switching Models

- `/model` — interactive model selector
- `/model <name>` — direct switch (accepts family slug, alias, or partial name)
- `--model <name>` at launch
- `DEVIN_MODEL` environment variable
- Config file: `{ "agent": { "model": "adaptive" } }`

### Adaptive

`/model adaptive` — Cognition's intelligent model router. Automatically selects the best model for each task. Simple tasks → fast/cheap models. Complex tasks → capable models.

- Best default for most users
- Fixed per-token rate on self-serve ($0.50 In / $2.00 Out / $0.10 cache read)
- Enterprise: metered in ACUs or variable-token credits
- Be specific with prompts to help Adaptive route correctly
- Staying on the same model across turns enables prompt caching (Adaptive considers this when routing)

### Subagent Model Selection

- `subagent_general` → YOUR model (inherits parent — free on this fleet's GLM-5.2 High parent, expensive on premium parents)
- Custom subagents → `model:` field if set, otherwise default subagent model
- `subagent_explore` → withdrawn; `subagent-guard.js` denies the dispatch (fleet policy: `subagent_general` only)

Admins can override the default subagent model via org settings (Subagent router / specific model / None to disable).

---

## Skills System

Skills are reusable prompts and workflows that extend the agent's capabilities. They are NOT always-on — they're invoked on demand.

### Discovery

- `devin skills list` — list all available skills
- `devin skills show <name>` — show details for a specific skill
- `devin skills paths` — show skill directory locations
- Skills appear in the system prompt's available skills list

### Locations

- **User (global):** `%APPDATA%\devin\skills\<name>\SKILL.md` and `~/.agents/skills/<name>/SKILL.md`
- **Project:** `.devin/skills/<name>/SKILL.md` and `.agents/skills/<name>/SKILL.md`
- **Copilot:** `.github/skills/` and `~/.copilot/skills/` (auto-discovered, toggled via `copilot` key under `read_config_from`)
- **Plugins:** plugin-provided skills load from plugin directories

### Skill Format

```markdown
---
name: my-skill
description: What this skill does and when to trigger it
version: 1.0.0
execution-mode: advisory | side_effecting
argument-hint: "[optional args]"
---

# Skill Title
Skill content — instructions, procedures, context
```

### Invocation

- Agent invokes via `skill` tool when a skill matches the request
- Multiple skills can be invoked in parallel if multiple match
- Skills can chain: one skill's output triggers another
- Skills can set `model:` in frontmatter to override the profile's model for subagent runs

### When Skills Load

Skills are loaded at session start. The system prompt lists all available skills with their trigger descriptions. The agent reads these descriptions to decide when to invoke.

When the same skill name loads from multiple locations, each copy surfaces with a location prefix (`/agents:foo`, `/claude:foo`) instead of appearing as indistinguishable duplicates.

---

## Rules System

Rules are always-on context blobs — instructions loaded into every session automatically. Unlike skills, they're always present.

### Discovery

- `devin rules list` — list all active rules
- `devin rules show <name>` — show rule content
- `devin rules paths` — show rule directory locations

### Sources

- **AGENTS.md** [Standard]: Loaded from cwd and ancestor directories up to repo root
- **.windsurf/rules/*.md** [Windsurf]: Always-on rules from Windsurf format
- **.cursor/rules/*.md** [Cursor]: Conditional rules from Cursor format
- **Plugin rules**: Plugin `AGENTS.md`/`AGENT.md`/`.windsurfrules` load as always-on rules

### Creating Rules

Place a markdown file in `.windsurf/rules/` (or the appropriate path for your format). The content becomes always-on context for every session in that directory.

**Keep rules short** — they add to every session's context budget. Use skills for detailed reference; use rules for critical always-present knowledge.

---

## Plugins

Plugins are bundles of skills, rules, hooks, MCP servers, and custom subagents from a repo, git URL, or local folder.

### Management

```bash
devin plugins install <source>   # Install a plugin
devin plugins list               # List installed plugins
devin plugins info <name>        # Show skills, hooks, rules, MCP, subagents
devin plugins update [name]      # Re-fetch at latest HEAD (or all plugins)
devin plugins remove <name>      # Remove a plugin
devin plugins prune              # GC plugin content no live scope requires
```

### What Plugins Can Contribute

- **Skills**: slash commands and agent-triggered context
- **Rules**: `AGENTS.md`/`AGENT.md`/`.windsurfrules` as always-on rules
- **Hooks**: `hooks.json` loaded alongside project hooks
- **MCP servers**: `.mcp.json` or inline `mcpServers` map run for the session
- **Custom subagents**: `agents/<name>/AGENT.md` surface as `<plugin>:<agent>` profiles

### Plugin Sources

- **git URL**: `devin plugins install https://github.com/acme/my-plugin`
- **git-subdir**: `devin plugins install acme/vendor-plugins#plugins/stripe`
- **local folder**: `devin plugins install ./my-plugin`
- **Claude-compatible**: `.claude-plugin/plugin.json` manifest used when no `.devin-plugin/plugin.json` exists

### Manifest Options

- `skills` field: controls where skills load from (or disable with `[]`)
- `forbiddenPlugins`: deny list (relative paths now resolve correctly)
- Required/optional plugin lists for dependency management

---

## MCP Servers

MCP (Model Context Protocol) servers extend the agent with external tools.

### Config Locations (v3000.3.22+)

MCP servers now live in dedicated config files (not in `config.json`):
- **User:** `~/.config/devin/mcp_config.json` (Windows: `%APPDATA%\devin\mcp_config.json`)
- **Project:** `.devin/mcp_config.json`
- **Local override:** `.devin/mcp_config.local.json`

Existing `mcpServers` entries in `config.json` are migrated automatically on startup.

### Management

```bash
devin mcp add <name> <command>    # Add a new MCP server
devin mcp list                    # List all configured servers
devin mcp get <name>              # Get details for a server
devin mcp remove <name>           # Remove a server
devin mcp login <name>            # Authenticate via OAuth
devin mcp logout <name>           # Remove stored OAuth credentials
devin mcp enable <name>           # Enable a disabled server
devin mcp disable <name>          # Disable without removing
```

### MCP Prompts

Prompts offered by connected MCP servers are available as slash commands: `/mcp__<server>__<prompt>` with arguments mapped positionally onto the prompt's declared arguments.

### OAuth

- `oauthResource` field (or `--oauth-resource` on `devin mcp add`/`devin mcp login`) overrides the RFC 8707 OAuth `resource` parameter — needed for identity providers like Microsoft Entra that reject requests containing `resource`.

### Plan Mode

Read-only MCP tools (annotated `readOnlyHint: true`) are allowed in Plan mode for context gathering. Listing MCP servers, tools, and resources is also allowed.

---

## Sandbox

OS-level process sandboxing for the exec tool. Research Preview.

### Activation

```bash
devin --sandbox --permission-mode autonomous
```

When active, Autonomous is the ONLY permission mode available. The sandbox enforces:
- **Filesystem**: writable roots from granted `Write(...)` scopes, readable roots from `Read(...)` scopes
- **Network**: domain allow/deny lists filter connections
- **Commands reaching blocked network hosts** surface a permission prompt (not silently blocked)

### Platform Support

- **macOS**: seatbelt
- **Linux**: bwrap + seccomp
- **Windows**: check `devin sandbox setup` for prerequisites

### Enterprise Enforcement

Org sandbox enforcement applies to running sessions. Team settings refreshed at each prompt. Turning on required sandboxing mid-session refuses further prompts with a message to restart.

---

## ACP (Agent Client Protocol)

Run Devin as an ACP server over stdio, enabling integration with editors (JetBrains, Zed, Xcode) and other ACP clients.

### Agent Types

- **default**: The standard Devin agent with all tools
- **summarizer**: No tools — model outputs summary, persisted to `~/.local/share/devin/summaries/<session_id>.md`
- **review**: Read-only + shell tools — reviews diffs for correctness, style, security, performance, completeness

### Model Selection

```bash
devin acp --model <name>     # Default model for every ACP session
# or
DEVIN_MODEL=<name> devin acp # Via environment variable
```

Accepts the same fuzzy names as `/model` (family slug, alias, partial name).

### Cloud Relay (insiders)

`devin acp --cloud` relays the ACP connection to Devin cloud instead of running the local agent.

### ACP Slash Commands

These commands work from any ACP client (Devin Desktop, JetBrains, Zed):
`/btw`, `/loop`, `/mcp`, `/context`, `/add-dir`, `/undo-add-dir` (alias `/remove-dir`), `/workspace` (alias `/workspaces`)

---

## Slash Commands

### Mode Switching
| Command | Description |
|---------|-------------|
| `/mode` | Show current mode |
| `/mode <name>` | Switch mode (normal, accept-edits, smart, plan, bypass; autonomous in sandbox) |
| `/normal` | Normal mode |
| `/accept-edits` | Accept Edits mode |
| `/smart` | Smart mode |
| `/plan` | Plan mode |
| `/ask <question>` | Ask mode (oneshot question) |
| `/bypass` | Bypass mode (aliases: `/yolo`, `/dangerous`) |

### Model Switching
| Command | Description |
|---------|-------------|
| `/model` | Show model selector |
| `/model <name>` | Switch to named model |
| `/model adaptive` | Switch to Adaptive router |

### Session Management
| Command | Description |
|---------|-------------|
| `/resume` | Open interactive session picker |
| `/resume <id>` | Resume session by ID |
| `/ls` | List recent sessions in current directory (alias: `/list-sessions`) |
| `/ls --all` | List all sessions across all directories |
| `/continue` | Resume most recent session |
| `/continue <id>` | Resume session by ID |
| `/rm-session <id>` | Irreversibly delete a session |

### Workspace
| Command | Description |
|---------|-------------|
| `/workspace` | List workspace directories (alias: `/workspaces`) |
| `/add-dir <path>` | Add additional workspace directory |
| `/undo-add-dir <path>` | Remove a workspace directory (alias: `/remove-dir`) |

### Navigation & Control
| Command | Description |
|---------|-------------|
| `/help` | See all available commands |
| `/exit` or `/quit` | Exit application |
| `/clear` or `/new` | Clear conversation history |
| `/compact` | Force conversation compaction |
| `/shortcuts` | List and interactively rebind keybindings |

### Automation
| Command | Description |
|---------|-------------|
| `/loop <prompt>` | Run a prompt then auto-review the diff in a loop (requires clean git state) |

### Extensibility
| Command | Description |
|---------|-------------|
| `/hooks` | List all loaded hooks with IDs, event types, source paths |

### Account & System
| Command | Description |
|---------|-------------|
| `/login` | Authenticate with Devin |
| `/logout` | Clear stored credentials and exit |
| `/update` | Check for and install updates |
| `/upgrade` | Upgrade subscription plan |
| `/bug` | Report a bug to Devin CLI developers |

### Session Info
| Command | Description |
|---------|-------------|
| `/session-stats` | Show usage dimensions (credits, ACUs, agent messages, turn continuations, token usage) |
| `/context` | Show context window usage |

---

## Keybindings

Configurable via `keymap` section in `config.json`:

```json
{
  "keymap": {
    "global": {
      "clear_screen": "ctrl-shift-k"
    }
  }
}
```

`/shortcuts` lists every binding across all contexts, shows each action's `context.action` identifier, and lets you rebind interactively. `Ctrl+C` cannot be unbound.

### Key Shortcuts

| Shortcut | Description |
|----------|-------------|
| `Shift+Tab` | Cycle permission modes (Normal → Accept Edits → Smart → Bypass → Autonomous) |
| `Ctrl+C` | Clear input text, or cancel running agent |
| `Esc` | Cancel running agent |
| `Shift+Enter` | Insert newline (multi-line input) |
| `Ctrl+V` / `Shift+Insert` | Paste from clipboard |
| `Ctrl+G` | Open external editor |
| `Ctrl+O` | Open full-screen thinking trace viewer |
| `Ctrl+B` | Background a running foreground subagent |
| `@` | Mention files to add as context |
| `↓` then `Enter` | Open subagent panel (when background subagents running) |

---

## Session Management

### Launch Options

```bash
devin                            # Interactive REPL (no prompt)
devin -- your prompt here        # REPL with initial prompt
devin -p "prompt"                # Single-turn, print response and exit
devin -p -- prompt words here    # Same, with -- separator
devin -c                         # Continue most recent session
devin -r                         # Pick from recent sessions
devin -r <session-id>            # Resume specific session
devin --prompt-file <file>       # Load initial prompt from file
devin --export [path]            # Export conversation to file (after each turn)
devin --agent-config <file>      # Declarative agent config (JSON/YAML, strict parsing)
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `DEVIN_PERMISSION_MODE` | Set permission mode |
| `DEVIN_MODEL` | Set default model |
| `DEVIN_SANDBOX` | Enable sandbox |
| `HUSKY=0` | Disable all husky hooks (inherited from project, not Devin-specific) |

### Log Files

Old log files are gzip-compressed on startup — logs from finished processes untouched for 48 hours become `.log.gz`. Still searchable with `zgrep` or `rg -z`.

---

## Optimization Patterns

### Cost Optimization

1. **Always dispatch `subagent_general`** — the only profile fleet policy permits (`rules/devin-subagent-profile-policy.md`). On this fleet it inherits GLM-5.2 High (free). Research/read-only behavior belongs in the task prompt; there is no cheaper profile to switch to.

2. **Pin cheaper models on custom subagents**. The `model:` frontmatter field is the only way to run a write-capable subagent on a cheaper model than the parent.

3. **Use Adaptive** (`/model adaptive`) as your default. It routes simple tasks to cheap models automatically. Switch to a specific model only when you need particular reasoning capabilities.

4. **`/compact` when context grows**. Force compaction to reduce token usage in long sessions. Auto-compaction happens silently; explicit `/compact` confirms in the transcript.

5. **GPT-5.6 Luna for cheap work**: $0.2/MTok in, $1.2/MTok out — 25x cheaper than Opus. Good for routine tasks.

6. **GLM-5.2 is free**: 200K context, $0 cost. Good for exploration and simple tasks.

### Parallelism

1. **Launch background subagents in parallel** for independent tasks. The parent continues working while they run.

2. **Fan-out with `swarm-subagent` skill** or `dispatch` skill for decomposable work across multiple subagents.

3. **Nesting**: Use `max-nesting` on custom profiles for multi-level delegation. Each level multiplies cost — use deliberately.

4. **Interrupt safety**: Interrupting the parent parks subagents, doesn't kill them. Safe to interrupt and redirect.

### Workflow Tricks

1. **Megaplan keywords** in Plan mode (`megaplan`, `ultraplan`, `masterplan`) trigger deeper planning + mandatory clarifying question. Use for complex multi-step work.

2. **`/loop <prompt>`** runs a prompt then auto-reviews the diff in a loop. Requires clean git state to start. Good for iterative refinement.

3. **Editable command approvals**: When a shell command prompts, "Edit command" lets you tweak it inline before approving. "Describe change to command" gives a plain-language rewrite via a fast model (out-of-band, doesn't enter conversation).

4. **`@` file mentions** pick up files created/moved/deleted during the session (not stale from startup).

5. **Image paste** with Ctrl+V — attached images tell the model where the file lives on disk.

6. **`--prompt-file <file>`** for loading complex initial prompts from a file — good for reproducible workflows.

7. **`-p` (print mode)** for scripts and automations — single-turn, no REPL, prints response to stdout and exits.

8. **`--export`** exports conversation to a file after each turn — good for audit trails.

### Permission Tricks

1. **Global "always allow"**: Permission prompts now offer "Yes, always allow `<cmd>` commands in all projects" saved to user-level config. Web-fetch prompts have an equivalent "always allow all web fetches" option.

2. **Scoped program-runner approvals**: `uv run ruff check` offers to allow `uv run ruff` not broad `uv run`. Also applies to `poetry run`, `pdm run`, `pipenv run`, `rye run`, `hatch run`, `pnpm exec`, `pnpm dlx`, `npm exec`, `yarn dlx`, `bun run`.

3. **Permission rules in config**: Pre-approve safe actions and block dangerous ones via `permissions.allow`/`deny`/`ask` in config files. Deny always wins over ask, ask always wins over allow.

4. **`--respect-workspace-trust false`** skips the trust prompt in non-interactive mode (print mode cannot show the prompt and fails in untrusted directories without this).

### Subagent Workflow Tricks

1. **Resume failed background subagents in foreground** to grant previously-denied permissions.

2. **Ctrl+B to background a foreground subagent** mid-run if you want the parent to continue while it works.

3. **Press `f` in the subagent panel** to foreground a background subagent and see its output inline.

4. **Subagent activity survives session reload** — the panel still reflects your subagents after resuming.

5. **A subagent's approval prompt shows the command and names the requesting subagent** — you always know who's asking.

### ACP Integration

1. **`devin acp --model <name>`** sets the default model for every ACP session.

2. **`devin acp --cloud`** (insiders) relays to Devin cloud instead of running locally.

3. **ACP slash commands** (`/btw`, `/loop`, `/mcp`, `/context`, `/add-dir`, `/workspace`) work from any ACP client — JetBrains, Zed, Xcode, Devin Desktop.

4. **ACP resource links and `<ref_file>` links** show the file's basename on Windows and build well-formed `file:///` URIs.

### Cloud Integration

```bash
devin cloud drs whoami            # Check DRS config (org, API endpoint, auth)
devin cloud drs sandbox-create    # Create a sandbox session for testing repo setup
devin cloud drs blueprint-list    # List environment blueprints
devin cloud drs blueprint-create  # Create a new blueprint
devin cloud drs build             # Trigger an environment build and wait
devin cloud drs build-start       # Trigger without waiting
devin cloud drs build-wait        # Wait for a started build
devin cloud drs build-logs        # Fetch build logs
devin cloud drs secret-create     # Create an org-level secret
```

### Outposts (Worker Nodes)

```bash
devin worker start                # No token needed — creates outpost with CLI login
devin worker start --name <name>  # Name the outpost
```

Downloads the correct `devin-remote` binary for the platform. Windows x64 now works (fixed `os error 10106` crash).

---

## Quick Reference Card

```
PERMISSION MODES:    /normal  /accept-edits  /smart  /bypass  (autonomous with --sandbox)
AGENT MODES:         /normal  /plan  /ask
MODEL:               /model  /model adaptive  /model opus  /model sonnet
SUBAGENTS:           subagent_general (only allowed profile — your model, full tools)
PROFILES:            devin-default, devin-builder, devin-researcher, devin-reviewer,
                     devin-planner, devin-ops, devin-security, devin-shipper,
                     devin-writer, devin-business, devin-auditor, devin-governance,
                     devin-architect, devin-compliance, devin-debugger, devin-evals,
                     devin-forensics, devin-migration, devin-sre, devin-tester
SWITCH MODE:         Shift+Tab  or  /mode <name>
INTERRUPT:           Ctrl+C or Esc (parks subagents, doesn't kill)
COMPACT:             /compact
LOOP:                /loop <prompt>
KEYBINDINGS:         /shortcuts
SESSION STATS:       /session-stats
HELP:                /help
```

---

## Profile Matrix

> **Status note (2026-09):** the `devin-*` entries below are persona **specs** in `~/.devin/agents/` — they are NOT dispatchable as `profile=` values on `run_subagent` (the spec dir is not wired to the resolver; dispatching one fails to start). The only allowed profile is `subagent_general`; use a spec's persona by pasting its name/role into the task prompt. Verified: `devin-researcher` dispatch failed 2026-09-19, `subagent_explore` denied 2026-09-20 — see `rules/devin-subagent-profile-policy.md` and `docs/proposals/PROPOSAL-2026-09-19-subagent-profile-enforcement-alignment.md`.

Custom subagent profiles in `.devin/agents/`. Each is a purpose-tuned configuration with its own model, tools, persona, and authority boundary. The root agent (devin-default) auto-selects the right profile based on task type; operator can override.

**Versioning:** SemVer — major = persona/authority change, minor = skill/tool/model change, patch = wording fix.

**Skill scoping:** Prompt-guided — profile system prompt lists which skills to use. All skills remain loaded at session level.

**Orchestration:** Root agent (devin-default) coordinates multi-profile workflows. It has the conversation context to sequence research → build → review → ship.

| Profile | Model | Cost | Tools | Nest | Version | Purpose |
|---------|-------|------|-------|------|---------|---------|
| `devin-default` | glm-5-2 | Free | Full | 1 | 1.0.0 | General purpose (current baseline) |
| `devin-builder` | glm-5-2 | Free | Full (no git mutations) | 2 | 1.0.0 | TDD-first code implementation |
| `devin-researcher` | glm-5-2 | Free | Read-only | 0 | 1.0.0 | Codebase exploration, web research |
| `devin-reviewer` | glm-5-2 | Free | Read + git read-only | 0 | 1.0.0 | PR review, code quality |
| `devin-planner` | glm-5-2 | Free | Read-only | 1 | 1.0.0 | Architecture, megaplan keywords |
| `devin-ops` | glm-5-2 | Free | Full | 1 | 1.0.0 | Incident response, fleet health |
| `devin-security` | glm-5-2 | Free | Read + security tools | 0 | 1.0.0 | Vulnerability scanning, audit |
| `devin-shipper` | glm-5-2 | Free | Full (procedural) | 0 | 1.0.0 | Test → scan → PR → merge |
| `devin-writer` | glm-5-2 | Free | Read + write (docs only) | 0 | 1.0.0 | Blog, social, docs, changelogs |
| `devin-business` | glm-5-2 | Free | Read + write (biz docs) | 0 | 1.0.0 | ICPs, proposals, deal memos |
| `devin-auditor` | glm-5-2 | Free | Read-only | 0 | 1.0.0 | Evidence verification, reproducibility |
| `devin-governance` | glm-5-2 | Free | Read-only | 0 | 1.0.0 | Fleet governance, skill audits |
| `devin-architect` | glm-5-2 | Free | Read-only + research | 1 | 1.0.0 | System design, interface contracts, component boundaries |
| `devin-compliance` | glm-5-2 | Free | Read + exec + write (compliance) | 0 | 1.0.0 | Regulatory alignment, NIST AI RMF, ISO 42001, GDPR, SOC 2 |
| `devin-debugger` | glm-5-2 | Free | Read + exec + write | 1 | 1.0.0 | Reproduce, trace, isolate, fix bugs |
| `devin-evals` | glm-5-2 | Free | Read + exec + write | 0 | 1.0.0 | AI evaluation engineering, cross-runtime validation |
| `devin-forensics` | glm-5-2 | Free | Read-only + exec | 0 | 1.0.0 | Git and bus forensics, timeline reconstruction |
| `devin-migration` | glm-5-2 | Free | Full | 1 | 1.0.0 | Repo cloning, config transfer, fleet topology, onboarding |
| `devin-sre` | glm-5-2 | Free | Read + exec + write | 1 | 1.0.0 | Proactive reliability, monitoring, SLOs, runbooks |
| `devin-tester` | glm-5-2 | Free | Read + exec + write | 0 | 1.0.0 | Test suite design, coverage analysis, smoke tests |

> **Model policy:** All profiles pinned to `glm-5-2` (free). Premium models (opus/sonnet/codex) are **Operator-only** via in-session `/model` — agents MUST NOT self-escalate. See `operator-model-switching-guide.md`.

### Installed Plugins

| Plugin | Version | Skills | Rules |
|--------|---------|--------|-------|
| `ponytail` | v4.8.4 | 6 (ponytail-review, ponytail-audit, ponytail-debt, ponytail-gain, ponytail-help, ponytail) | AGENTS.md (always-on) |
| `compound-engineering` | v3.21.0 | 32 (ce-babysit-pr, ce-brainstorm, ce-code-review, ce-commit, ce-debug, ce-plan, ce-work, lfg, ...) | AGENTS.md (always-on) |

### Configured MCP Servers

| Server | Transport | Auth | Purpose |
|--------|-----------|------|---------|
| `github` | stdio | GITHUB_PERSONAL_ACCESS_TOKEN env var (1Password) | GitHub PR/issue/repo access |

---

## Profile Selection Guide

### Auto-Selection (Root Agent Decides)

The root agent (devin-default) analyzes the task and spawns the appropriate profile. Operator can override by naming a profile explicitly.

### Task → Profile Mapping

The "Profile" column names the **persona spec** to apply — dispatch `subagent_general` and state the persona in the task prompt (e.g., "You are devin-builder: TDD-first…"). Do not pass these names to `profile=` — they are not registered dispatch targets.

| Task | Profile | Why |
|------|---------|-----|
| "Build this feature" | devin-builder | TDD-first, can spawn researcher |
| "Review this PR" | devin-reviewer | Read-only, git tools |
| "Research X" | devin-researcher | Free, read-only, plan mode |
| "Plan the architecture" | devin-planner | Free; Operator may `/model opus` for deep reasoning, megaplan |
| "Something is broken" | devin-ops | Fast triage, free, can spawn researcher |
| "Security audit" | devin-security | Read-only + security tools |
| "Ship this" | devin-shipper | Test → scan → PR → merge |
| "Write a blog post" | devin-writer | Write to docs only |
| "Build an ICP" | devin-business | Business skills |
| "Verify this claim" | devin-auditor | Free, evidence verification |
| "Audit the skill fleet" | devin-governance | Fleet governance skills |
| "Design the system architecture" | devin-architect | Read-only + research, can spawn validation children |
| "Check regulatory compliance" | devin-compliance | NIST AI RMF, ISO 42001, GDPR, SOC 2 mapping |
| "Debug this failure" | devin-debugger | Read + exec + write, can spawn parallel investigation |
| "Run an eval suite" | devin-evals | AI evaluation engineering, cross-runtime validation |
| "Audit git history" | devin-forensics | Git/bus forensics, timeline reconstruction |
| "Migrate this repo" | devin-migration | Full tools, pre-flight discipline, can spawn parallel setup |
| "Check SLO compliance" | devin-sre | Proactive reliability, monitoring, can spawn parallel checks |
| "Design test coverage" | devin-tester | Test suite design, coverage analysis, smoke tests |
| "Just do the thing" | devin-default | General purpose, all skills |

### When NOT to Delegate

- Task is quick (< 1 minute) — handle in root agent
- Task spans multiple domains (research + build + commit) — root agent orchestrates
- Operator wants interactive back-and-forth — root agent handles
- Task requires ask_user_question — subagents can't prompt

### Multi-Profile Workflows (Root Agent Orchestrates)

| Workflow | Sequence |
|----------|----------|
| Feature development | researcher (explore) → builder (implement) → reviewer (review) → shipper (ship) |
| Security hardening | security (audit) → builder (fix) → shipper (ship) |
| Incident response | ops (triage) → researcher (investigate) → builder (fix) → shipper (ship) |
| Architecture redesign | planner (design) → researcher (validate) → builder (implement) → reviewer (review) → shipper (ship) |
| Content publication | researcher (gather) → writer (draft) → auditor (fact-check) |

## Skill Chains
- For free-tier models beyond Devin's built-in set -> `[reasoning-router]` (`python ~/bin/reasoning_router.py models`)
- For canonical Devin to opencode delegation command -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py delegate`)
