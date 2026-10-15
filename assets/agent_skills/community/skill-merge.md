---
name: skill-merge
description: Merge two overlapping skills into one — combine frontmatter, body sections, chains, and bundled files. Use after [skill-diff] determines two skills should become one.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<keep-skill> <absorb-skill>"
category: fleet-ops
status: candidate
---
## SKILL_INVOKE

Before any stateful action (file writes, git operations), emit:

```
Type: SKILL_INVOKE
To: all
Message: [skill=skill-merge] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

# skill-merge

Merge two overlapping skills into a single skill. The `keep-skill` absorbs
content from `absorb-skill`, then `absorb-skill` is converted to a redirect
stub. Produces a merge receipt on the bus.

## When to Use

- After `[skill-diff]` returns verdict MERGE or DEPRECATE-ONE
- When two skills have the same name and one is clearly the successor
- When a skill was split unnecessarily and should be recombined

## Usage

```bash
[skill-merge] keep-skill absorb-skill    # absorb-skill content merges into keep-skill
```

## Execution

### 1. Pre-flight checks

- Verify both skills exist: `ls ~/.agents/skills/<name>/SKILL.md`
- Run `[skill-diff] <keep-skill> <absorb-skill>` and review the verdict
- If verdict is KEEP-BOTH, STOP — do not merge non-overlapping skills
- Confirm with operator before proceeding

### 2. Merge frontmatter

- Keep `keep-skill`'s `name` and `description` (unless `absorb-skill`'s is strictly better)
- Take the higher `version` number, bump patch: `max(a,b) + 0.0.1`
- Merge `execution-mode`: if either is `side_effecting`, result is `side_effecting`
- Merge `argument-hint`: combine if both accept args, keep the more general one

### 3. Merge body

- Start from `keep-skill`'s body
- For each H2 section in `absorb-skill` not in `keep-skill`, append it
- For overlapping H2 sections, merge content (keep both variants with a comment)
- Merge "When to Use" lists (deduplicate)
- Merge "Skill Chains" sections (deduplicate by target skill name)

### 4. Merge bundled files

```bash
for dir in scripts references assets agents; do
  if [ -d ~/.agents/skills/<absorb-skill>/$dir ]; then
    mkdir -p ~/.agents/skills/<keep-skill>/$dir
    cp -rn ~/.agents/skills/<absorb-skill>/$dir/* ~/.agents/skills/<keep-skill>/$dir/
  fi
done
```

### 5. Convert absorb-skill to redirect stub

```bash
cat > ~/.agents/skills/<absorb-skill>/SKILL.md << 'STUB'
---
name: <absorb-skill>
description: "MERGED into <keep-skill> on YYYY-MM-DD. Use /<keep-skill> instead."
version: 0.0.0
execution-mode: advisory
status: merged
---
> **MERGED into `/<keep-skill>`** as of YYYY-MM-DD.
> This file is retained as a routing stub. See `~/.agents/skills/<keep-skill>/SKILL.md`.
STUB
```

### 6. Update routing

In `~/.agents/skill-routing.md`, add alias entries:
```
- "<old trigger>" -> /<keep-skill> (replaces merged /<absorb-skill>)
```

### 7. Update chains

In `~/.agents/rules/skill-chains.md`, replace all `/<absorb-skill>` references
with `/<keep-skill>`.

### 8. Post merge receipt

```
Type: STATUS
To: all
Message: [skill-merge] Merged /<absorb-skill> into /<keep-skill>. <N> sections combined, <M> files copied. Stub created. Routing + chains updated.
```

### 9. Verify

```bash
grep -c "<keep-skill>" ~/.agents/skills/<keep-skill>/SKILL.md
grep -c "MERGED" ~/.agents/skills/<absorb-skill>/SKILL.md
grep -c "<absorb-skill>" ~/.agents/rules/skill-chains.md  # should be 0 (replaced)
```

## Output Format

```
skill-merge | <keep-skill> absorbs <absorb-skill>
══════════════════════════════════════════

Sections merged: N
Files copied: M
Stub created: ~/.agents/skills/<absorb-skill>/SKILL.md
Routing aliases: K entries updated
Chain references: J references redirected
Bus receipt: STATUS posted

Next: [skill-test] to validate the merged skill, [skill-demote] to archive the stub
```

## Skill Chains

### Mandatory

- Before `[skill-merge]` → `[skill-diff]` MUST confirm merge is appropriate

### Advisory

- After `[skill-collision-detect]` finds duplicates → `[skill-diff]` → `[skill-merge]`
- After `[skill-merge]` → `[skill-test]` to validate the merged result
- After `[skill-merge]` → `[skill-demote]` to archive the absorb-skill stub

## Authority

- **T1 (TRUSTED)**: May run with operator confirmation
- **T2 (Active/High)**: May run with operator confirmation
- **T3 (Medium)**: Operator approval required
- **T4 (Probationary)**: May not run
- **Operator**: Override any restriction
