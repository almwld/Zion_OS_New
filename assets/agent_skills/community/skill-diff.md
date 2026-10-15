---
name: skill-diff
description: Compare two skills side-by-side — frontmatter, body, chains, and referenced files. Use when deciding whether to merge, deprecate, or differentiate overlapping skills.
version: 0.1.0
execution-mode: advisory
argument-hint: "<skill-a> <skill-b>"
category: fleet-ops
status: candidate
---
# skill-diff

Compare two SKILL.md files structurally — frontmatter fields, body content,
line counts, referenced scripts/assets, chain entries, and routing triggers.
Produces a tabular diff summary that makes merge/differentiate decisions
evidence-based instead of guesswork.

## When to Use

- After `[skill-collision-detect]` finds a name or description collision
- When two skills seem to do the same thing and you need to decide: merge, deprecate, or keep both
- Before `[skill-merge]` to understand what would be combined
- When reviewing a skill rename or refactor to verify nothing was lost

## Usage

```bash
[skill-diff] skill-a skill-b    # Compare two skills by name
```

## Execution

### 1. Resolve paths

```bash
A="$HOME/.agents/skills/<skill-a>/SKILL.md"
B="$HOME/.agents/skills/<skill-b>/SKILL.md"
```

Verify both exist. If either is missing, report and stop.

### 2. Extract and compare frontmatter

Parse YAML frontmatter from both files. Compare these fields:
- `name`, `description`, `version`, `execution-mode`, `argument-hint`, `status`

### 3. Compare body structure

```bash
wc -l "$A" "$B"
diff "$A" "$B" | head -80
```

Extract and compare:
- H2 section headers (`grep '^## '`)
- Chain references (`grep -oE '/[a-z][-a-z0-9]*' | sort -u`)
- Referenced scripts (`grep -oE '~/.agents/skills/[^/]*/(scripts|references|assets)/[^ ]*'`)
- Routing triggers (`grep "<skill-name>" ~/.agents/skill-routing.md`)

### 4. Compare filesystem footprint

```bash
find "$HOME/.agents/skills/<skill-a>/" -type f | wc -l
find "$HOME/.agents/skills/<skill-b>/" -type f | wc -l
```

List bundled files (scripts, references, assets) in each.

### 5. Render comparison table

Output a side-by-side table:

```
skill-diff | <skill-a> vs <skill-b>
══════════════════════════════════════════

| Field           | <skill-a>              | <skill-b>              |
|-----------------|------------------------|------------------------|
| Lines           | N                      | M                      |
| Version         | x.y.z                  | x.y.z                  |
| Execution-mode  | advisory               | side_effecting         |
| Description     | ...                    | ...                    |
| Files bundled   | N                      | M                      |
| Chain refs      | N unique               | M unique               |
| Routing triggers| N                      | M                      |

Key differences:
- <field>: <a-value> vs <b-value>
- <unique-to-a>: ...
- <unique-to-b>: ...

Verdict: <MERGE | DIFFERENTIATE | KEEP-BOTH | DEPRECATE-ONE>
Rationale: <one sentence>
```

### 6. Verdict logic

- **MERGE**: Same name or >70% description overlap AND >50% body overlap
- **DIFFERENTIATE**: Same domain but distinct execution-mode, target runtime, or non-overlapping body — rename one to clarify scope
- **KEEP-BOTH**: Different domains, collision was cosmetic (e.g., `.system/` vs fleet root)
- **DEPRECATE-ONE**: One is clearly superseded (newer version, superset of features)

## Output Format

```
skill-diff | <skill-a> vs <skill-b>
══════════════════════════════════════════

<comparison table>

Verdict: <action>
Next: [skill-merge] if MERGE, [skill-demote] if DEPRECATE-ONE, manual rename if DIFFERENTIATE
```

## Skill Chains

### Mandatory

None — read-only comparison.

### Advisory

- After `[skill-collision-detect]` finds duplicates → `[skill-diff]` to understand the overlap
- After `[skill-diff]` → `[skill-merge]` if verdict is MERGE
- After `[skill-diff]` → `[skill-demote]` if verdict is DEPRECATE-ONE
- Before `[skill-merge]` → `[skill-diff]` to scope what gets combined

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
