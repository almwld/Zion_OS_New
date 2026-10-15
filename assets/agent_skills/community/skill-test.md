---
name: skill-test
description: Validate skills -- check for broken commands, stale paths, missing tools, format compliance.
version: 0.1.0
execution-mode: advisory
argument-hint: "[all | SKILL_NAME | lint | chains | stale]"
category: governance-compliance
status: candidate
---
# Skill Test

Validate that skills are well-formed and their referenced commands/paths actually work.

## When to Use
- After creating new skills (verify they work)
- After moving files or renaming modules (skills may reference old paths)
- Periodically (quarterly skill health check)
- After upgrading tools (python version, gh CLI, etc.)

## Context Gathering

Before executing this skill, gather the following context:
- Detect current platform: `python -c "import platform; print(platform.system())"`
- On Windows: use PowerShell or git-bash for bash examples
- Skill roots: `~/.agents/skills/`, `~/.devin/skills/`, `~/.agents/skills/`

## Operations

### lint
Check all skills for format compliance:
```bash
for dir in ~/.agents/skills/*/ ~/.devin/skills/*/ ~/.agents/skills/*/; do
    skill=$(basename "$dir")
    f="$dir/SKILL.md"
    [ -f "$f" ] || continue
    [ "$skill" = "_research" ] || [ "$skill" = "_index" ] && continue

    errors=""

    # Check frontmatter
    head -1 "$f" | grep -q "^---$" || errors="${errors}  NO FRONTMATTER\n"
    grep -q "^name:" "$f" || errors="${errors}  MISSING name\n"
    grep -q "^description:" "$f" || errors="${errors}  MISSING description\n"
    grep -q "^version:" "$f" || errors="${errors}  MISSING version\n"

    # Check in _index
    grep -q "skills/$skill/" ~/.agents/skills/_index/SKILL.md 2>/dev/null || errors="${errors}  NOT IN _index\n"

    # Check in routing rules
    grep -qE "/${skill}([[:space:]]|$)" ~/.agents/skill-routing.md 2>/dev/null || errors="${errors}  NOT IN routing rules\n"

    # Check mandatory chains for side_effecting skills (per skill-chains-mandatory.md)
    exec_mode=$(grep -m1 "^execution-mode:" "$f" 2>/dev/null | awk '{print $2}' | tr -d '\r')
    if [ "$exec_mode" = "side_effecting" ]; then
        grep -q "### Mandatory" "$f" 2>/dev/null || errors="${errors}  NO MANDATORY CHAINS (side_effecting requires ### Mandatory section)\n"
        grep -q "## Authority" "$f" 2>/dev/null || errors="${errors}  NO AUTHORITY SECTION (side_effecting requires ## Authority section)\n"
    fi

    if [ -n "$errors" ]; then
        echo "FAIL: $skill"
        echo -e "$errors"
    fi
done
```

### chains
Validate mandatory chains and authority sections for all `side_effecting` skills (per `skill-chains-mandatory.md`):
```bash
total=0; compliant=0; noncompliant=0

for dir in ~/.agents/skills/*/ ~/.devin/skills/*/ ~/.agents/skills/*/; do
    f="$dir/SKILL.md"
    [ -f "$f" ] || continue
    skill=$(basename "$dir")
    [ "$skill" = "_research" ] || [ "$skill" = "_index" ] && continue

    exec_mode=$(grep -m1 "^execution-mode:" "$f" 2>/dev/null | awk '{print $2}' | tr -d '\r')
    [ "$exec_mode" = "side_effecting" ] || continue

    total=$((total + 1))
    has_mandatory=$(grep -c "### Mandatory" "$f" 2>/dev/null)
    has_authority=$(grep -c "## Authority" "$f" 2>/dev/null)

    if [ "$has_mandatory" -gt 0 ] && [ "$has_authority" -gt 0 ]; then
        compliant=$((compliant + 1))
    else
        noncompliant=$((noncompliant + 1))
        issues=""
        [ "$has_mandatory" -eq 0 ] && issues="$issues MISSING_MANDATORY"
        [ "$has_authority" -eq 0 ] && issues="$issues MISSING_AUTHORITY"
        echo "FAIL: $skill —$issues"
    fi
done

echo ""
echo "=== Chain Compliance ==="
echo "Total side_effecting: $total"
echo "Compliant: $compliant ($((compliant * 100 / (total > 0 ? total : 1)))%)"
echo "Non-compliant: $noncompliant"
[ "$noncompliant" -eq 0 ] && echo "✅ ALL COMPLIANT" || echo "❌ $noncompliant SKILLS NEED FIXING"
```

### portability
Check skills for cross-platform portability issues (Unix commands in PowerShell blocks, retired paths, missing platform preamble):
```bash
python ~/.agents/scripts/validate-skill-portability.py --root ~/.agents/skills
```
Or for a single skill:
```bash
python ~/.agents/scripts/validate-skill-portability.py --file ~/.agents/skills/<skill-name>/SKILL.md
```

Checks performed:
- Unix commands (`grep`, `awk`, `sed`, `df`, `lsof`, `pgrep`, etc.) inside ````powershell` blocks
- `/dev/null` in PowerShell blocks (outside quoted strings)
- Bare `~` in PowerShell without `$HOME`
- Bash-specific `$'\t'` syntax
- SSH commands without `ConnectTimeout`
- References to retired paths
- Missing platform detection preamble (for non-SSH shell commands)

### stale
Check for stale references in skill bodies:
```bash
for dir in ~/.agents/skills/*/ ~/.devin/skills/*/ ~/.agents/skills/*/; do
    f="$dir/SKILL.md"
    [ -f "$f" ] || continue
    skill=$(basename "$dir")
    [ "$skill" = "_research" ] || [ "$skill" = "_index" ] && continue

    # Check referenced Python modules exist
    grep -oE 'your_project\.[a-z_.]+' "$f" 2>/dev/null | sort -u | while read mod; do
        modpath=$(echo "$mod" | tr '.' '/')
        if [ ! -f "$modpath.py" ] && [ ! -d "$modpath" ]; then
            echo "STALE: $skill references $mod (not found)"
        fi
    done

    # Check referenced file paths exist
    grep -oE '(services|integrations|cognition|bus)/[a-z_]+\.py' "$f" 2>/dev/null | sort -u | while read path; do
        if [ ! -f "$path" ]; then
            echo "STALE: $skill references $path (not found)"
        fi
    done
done
```

### SKILL_NAME
Test a specific skill:
```bash
skill="$1"
for root in ~/.agents/skills ~/.devin/skills ~/.claude/skills; do
    f="$root/$skill/SKILL.md"
    [ -f "$f" ] && break
done

echo "=== Format ==="
# Check all required fields
# Check line count (40-120)
# Check has Output Format section

echo "=== Commands ==="
# Extract shell commands from code blocks
# Dry-run each (syntax check, not execution)

echo "=== References ==="
# Check all file paths exist
# Check all Python modules importable
# Check all CLI tools available (gh, python, git, etc.)
```

## Output Format
```
Skill Test | <scope>
═════════════════════

## Lint Results
- Passed: N skills
- Failed: N skills
  - <skill>: <issue>

## Stale References
- <skill>: references <path> (not found)

## Summary
Total: N skills, M issues, K stale references
```

## When to Run
- After `[skill-create]` (test the new skill)
- After `[bulk-edit]` (may have broken skill references)
- After adding mandatory chains to side_effecting skills (run `chains`)
- Monthly maintenance (run `all`)
