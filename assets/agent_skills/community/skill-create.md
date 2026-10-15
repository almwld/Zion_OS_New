---
name: skill-create
description: Guided skill creation -- generates a properly formatted SKILL.md with triggers, chains, and Base120 mapping.
version: 0.2.0
execution-mode: side_effecting
argument-hint: <skill-name>
status: tested
category: fleet-ops
providers:
  required: [python]
---
## Context Gathering

Before executing this skill, gather the following context:
- **Existing skills (!`ls ~/.agents/skills/ | wc -l` total)**: Run `ls ~/.agents/skills/ | sort | tr '\n' ', '`

# Skill Create Command

Interactive skill creation wizard. Generates a properly structured `~/.agents/skills/<name>/SKILL.md`.

## Usage

```bash
[skill-create] my-new-skill     # Start creation wizard for "my-new-skill"
[skill-create]                  # Start wizard (will ask for name)
```

## Execution

### 1. Validate name
- Must be lowercase kebab-case (`[a-z0-9-]+`)
- Must not collide with existing skills (check Live Context)
- If collision, warn and ask for alternative

### 2. Gather information by asking the operator

Ask these questions (one at a time, multiple-choice where possible):

**Q1: Category**
- Dev Workflow (test, build, commit, branch)
- Ops & Monitoring (health, services, logs, alerts)
- Agent Coordination (bus, dispatch, delegate, audit)
- Code Quality (audit, refactor, clean)
- Research & Analysis (search, compare, synthesize)
- Business & Strategy (pitch, runway, investor)
- Product Management (stories, prioritize, scope)
- Security & Compliance (scan, threat, legal)
- Architecture (API, MCP, diagram, dependency)
- Cognition & Memory (ledger, memory, decision)
- Analytical (Base120-mapped thinking tool)
- Session & Meta (tempo, context, handoff)

**Q2: When should this skill trigger?**
Write a trigger sentence (shown in routing rules):
Example: "when a test fails", "when the user mentions competitors", "before shipping a feature"

**Q3: What skills should it chain to?**
After this skill completes, what skill(s) naturally follow?
Example: "suggest [test-run] after fixing, [retrospective] if pattern is recurring"

**Q4: Base120 mapping (optional)**
Which mental model does this skill embody?
Example: "DE1 Root Cause Analysis", "IN2 Premortem", or "none (general tool)"

**Q5: Does it need dynamic context (DCI)?**
- Yes (will inject live data via `!`command`` shell execution)
- No (static instructions only)

**Q6: Does it accept arguments?**
- Yes (provide argument-hint example)
- No

**Q7: Does it parse local data sources (audit logs, transcripts, JSONL, CSV)?**
- If yes: SCHEMA-DISCOVERY PREREQ — before writing the spec, run a 5-minute schema check on each source. For JSONL: `head -1 <file>` and verify the field shape matches what the spec assumes. Specifically: don't assume a field is populated until you've grep'd a known case. Origin: 2026-05-07 — `[skill-usage]` proposal assumed `audit/tool-usage.jsonl` would carry the skill name; reality was `input_summary="n/a"` for `tool=="Skill"` entries. Caught only at synthesis time. Schema discovery at proposal time would have caught it before scaffolding.
- If no: skip.

### 3. Generate SKILL.md

Follow this template:
```markdown
---
name: <name>
description: <one-line description>. [Maps to <BASE120_CODE>.]
version: 0.1.0
execution-mode: advisory
argument-hint: "<hint>"   # only if accepts args
---

## Live Context                # only if DCI
<dynamic context lines using !`command` syntax>

# <Name> Command

<1-2 sentence explanation of what this does and when to use it.>

## When to Use
- <trigger condition 1>
- <trigger condition 2>

## Execution
<numbered steps with commands>

## Output Format
```
<Skill Name> | <context>
═════════════════════════
<structured output template>
```

## Base120 Context               # only if mapped
- Primary: **<CODE>** (<Name>)
- Related: **<CODE>** (<Name>), **<CODE>** (<Name>)
```

### Execution-mode reference

| Mode | Can edit | Can commit/push | Can bus post | Receipt required |
|---|---|---|---|---|
| `advisory` | No | No | No (read-only) | No |
| `remedial` | Yes | No | No | No |
| `side_effecting` | Yes | Yes | Yes | **Yes** — emit SKILL_INVOKE before any stateful action |

**SKILL_INVOKE format** (required for all `side_effecting` skills):
```
Type: SKILL_INVOKE
To: all
Message: [skill=<name>] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

This emission lets the krineia-watcher service agent create a cryptographic receipt for the invocation, satisfying Krineia Invariant 5 (Trust-Root Separation).

### 4. Create the file
```bash
mkdir -p ~/.agents/skills/<name>/
```
Then write `SKILL.md` with the generated content.

**After writing (or editing) any skill file, verify the content landed:**
```bash
grep -c "<unique phrase from your addition>" ~/.agents/skills/<name>/SKILL.md
# Must return >= 1; if 0, the write failed silently
wc -l ~/.agents/skills/<name>/SKILL.md
# Must be within 40-120 lines (template guideline); trim or justify before declaring done
```
This applies when editing existing skills too — always grep for a unique phrase from your change before declaring done.

### 5. Update skill-routing.md
Add the new skill's trigger to `~/.agents/skill-routing.md` in the appropriate section.

### 6. Update _index
**MANDATORY.** Add the new skill to `~/.agents/skills/_index/SKILL.md` in the correct alphabetical section, or run `python ~/.agents/skills/_regen_index.py` to regenerate the full index from frontmatter. Every skill must appear in the index. Freshness is gated at session close via `python ~/.agents/skills/_regen_index.py --check` (end-session step 1b2).

### 7. Update MEMORY.md skill count
Update the skill count in `~/.agents/MEMORY.md` (the fleet-wide memory file).
**NEVER write to `~/.claude/`, `~/.codex/`, or other tool-specific directories.**
If `~/.agents/MEMORY.md` does not exist, create it. Do not search for alternative MEMORY.md paths.

### 8. Chain completeness check
Grep `skill-chains.md` for the new skill name:
```bash
grep -c "<skill-name>" ~/.agents/rules/skill-chains.md
```
If result is 0, add a chain entry to `~/.agents/rules/skill-chains.md`.

**Important:** `skill-chains.md` is hook-managed — use `python3 -c` replace, NOT the Edit tool:
```bash
python3 -c "
with open('$HOME/.agents/rules/skill-chains.md', 'r') as f:
    content = f.read()
# Insert before the last '## Anti-Patterns' section
new_row = '| \`/<skill-name>\` | \`/<next-skill>\` (when/why), \`/<alt-skill>\` (alternative path) |'
content = content.replace('## Anti-Patterns', new_row + '\n\n## Anti-Patterns')
with open('$HOME/.agents/rules/skill-chains.md', 'w') as f:
    f.write(content)
"
# Verify the entry landed:
grep -c "<skill-name>" ~/.agents/rules/skill-chains.md
# Must return >= 1; if 0, the write failed silently
```
Format for the table row:
`| \`/<skill-name>\` | \`/<next-skill>\` (when/why), \`/<alt-skill>\` (alternative path) |`

### 9. Confirm
Report:
- Created file path
- Trigger added to routing rules
- Index entry added to `_index/SKILL.md`
- MEMORY.md count updated
- Chain entry verified in `skill-chains.md`
- Suggested test: `/<name>`

## Template Quality Checklist
- [ ] Has `version: 0.1.0` in frontmatter
- [ ] Has `execution-mode: advisory|remedial|side_effecting` in frontmatter
- [ ] If `side_effecting`: Has SKILL_INVOKE emission step before any stateful action
- [ ] Has "When to Use" section with trigger conditions
- [ ] Has "Output Format" with structured template
- [ ] Has Base120 mapping (if analytical/thinking skill)
- [ ] Between 40-120 lines
- [ ] No fabricated commands or paths
- [ ] Follows existing skill conventions (check 2-3 similar skills for style)
- [ ] Added to `_index/SKILL.md` in correct category
- [ ] Added to `skill-routing.md` with trigger
- [ ] MEMORY.md skill count updated

## Deprecation Protocol

When marking an existing skill DEPRECATED:

1. Add a deprecation notice at the top of the skill file (after frontmatter):
   ```
   > **DEPRECATED as of YYYY-MM-DD.** Use `/<replacement>` instead.
   ```

2. Find all consumers referencing the deprecated skill:
   ```bash
   grep -rl "<skill-name>" ~/.agents/skills/
   ```
   Patch each consumer to replace the deprecated reference with the replacement skill name.

3. Update `_index/SKILL.md` to mark the skill DEPRECATED (add `[DEPRECATED]` to its table row).

4. Add a routing alias in `skill-routing.md` so old trigger phrases route to the replacement:
   ```
   - "<old trigger phrase>" → `/<replacement>` (replaces deprecated `/<skill-name>`)
   ```
   Use `python3 -c` replace — `skill-routing.md` is hook-managed, NOT Edit tool.

5. Do NOT remove the skill file — keep it as a redirect stub for muscle memory. The stub body should be:
   ```markdown
   > **DEPRECATED as of YYYY-MM-DD.** Use `/<replacement>` instead.
   > This file is retained as a routing stub. See `~/.agents/skills/<replacement>/SKILL.md`.
   ```

6. Verify nothing in `skill-chains.md` still points to the deprecated name as the primary suggestion:
   ```bash
   grep "<skill-name>" ~/.agents/rules/skill-chains.md
   ```
   Update any chain entries that suggest the deprecated skill as a next step.

## Constraints

- **Must use `~/.agents/skills/<name>/SKILL.md` subdirectory format.** Flat .md files are silently ignored.
- Validate no name collision before creating.
- Keep generated skills between 40-120 lines.
- Always add the trigger to skill-routing.md.
- **Always add the skill to _index/SKILL.md.** The index must stay in sync.
- Always update MEMORY.md skill count.
- **Always verify chain completeness** — grep `skill-chains.md` for the new skill name after creation (Step 8).
- Always include Base120 mapping for analytical/thinking skills.
- **After any write or edit, grep for a unique phrase from your change.** Silent write failures happen; a 0-match grep is the signal. This applies to edits of existing skills as much as to new ones.
- **After committing a skill batch, run `git status -- ~/.agents/skills/` to confirm no skill files were omitted.** Files edited after the initial batch list was formed are silently left unstaged; this command catches them.
- **DESIGN.md status accuracy:** if a new skill includes a `DESIGN.md` section referencing HUMMBL primitives, every primitive must carry one of: `[STATUS: LIVE]`, `[STATUS: DESIGNED]`, or `[STATUS: PROPOSED]`. Before tagging LIVE, confirm the file exists (`ls hummbl_governance/services/<name>.py`). Presenting roadmap as reality is fabrication.

## Skill Chains

### Mandatory

None — file generation; skills are reviewed by `[skill-test]` before adoption.

### Advisory

- After `[skill-create]` → `[skill-test]` to validate the generated skill
- After `[skill-create]` → `[skill-export]` to port the skill to other agents
- Before `[skill-create]` → `[brainstorm]` to scope the skill's purpose and triggers

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator notification required
- **T4 (Probationary)**: May run with operator approval
- **Operator**: Override any restriction
