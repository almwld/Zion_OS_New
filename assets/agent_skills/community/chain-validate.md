---
name: chain-validate
description: Verify every skill referenced in Skill Chains sections actually exists in the registry. Catches dangling references to renamed, archived, or deleted skills.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--strict] [--fix]"
category: hummbl-research
status: candidate
---
# chain-validate

Scan all SKILL.md files' "Skill Chains" sections and `skill-chains.md` for
references to skills that don't exist on disk. Dangling references happen when
skills are renamed, archived, or deleted without updating consumers.

## When to Use

- After `[skill-merge]` or `[skill-archive]` to verify no dangling references remain
- After a batch skill rename
- Periodic health check (pair with `[chain-evolve]`)
- In CI to prevent merging SKILL.md files with broken chain references
- Before `[skill-test]` runs on a new skill to verify its chain targets exist

## Usage

```bash
[chain-validate]              # Report dangling references (exit 0 if clean, 1 if found)
[chain-validate] --strict     # Same, but exit 1 on any finding
[chain-validate] --fix        # Attempt to auto-fix by searching for renamed skills
```

## Execution

### 1. Build the skill registry

```bash
cd $HOME && python3 -c "
import os, re, glob

# Collect all skill names from SKILL.md frontmatter
skills = set()
for path in glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md')):
    with open(path, errors='replace') as f:
        content = f.read(4096)
    m = re.search(r'^name:\s*(\S+)', content, re.M)
    if m:
        skills.add(m.group(1).strip('\"'))

# Also check skills-full if it exists as a separate root
for path in glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md')):
    with open(path, errors='replace') as f:
        content = f.read(4096)
    m = re.search(r'^name:\s*(\S+)', content, re.M)
    if m:
        skills.add(m.group(1).strip('\"'))

print(f'REGISTRY: {len(skills)} skills')
for s in sorted(skills):
    print(f'  {s}')
" 2>&1
```

### 2. Extract chain references from all SKILL.md files

```bash
cd $HOME && python3 -c "
import os, re, glob

# Pattern: /skill-name in backticks or prose within Skill Chains sections
ref_pattern = re.compile(r'/(?:\[)?([a-z][-a-z0-9]*)(?:\])?(?:\s|$|[,)\`])')

findings = []
for path in sorted(glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md'))):
    skill_name = os.path.basename(os.path.dirname(path))
    with open(path, errors='replace') as f:
        content = f.read()
    # Find Skill Chains section
    chains_match = re.search(r'## Skill Chains.*?(?=\n## |\Z)', content, re.S)
    if not chains_match:
        continue
    chains_text = chains_match.group(0)
    refs = set(ref_pattern.findall(chains_text))
    # Filter out non-skill tokens (section names, etc.)
    refs = {r for r in refs if len(r) > 2 and r not in ('the','and','for','use')}
    for ref in sorted(refs):
        print(f'{skill_name}\t{ref}')
" 2>&1
```

### 3. Extract references from skill-chains.md

```bash
grep -oE '/[a-z][-a-z0-9]*' ~/.agents/rules/skill-chains.md | sort -u
```

### 4. Cross-reference and report

```bash
cd $HOME && python3 -c "
import os, re, glob, subprocess

# Build registry
skills = set()
for root in ['~/.agents/skills', '~/.agents/skills-full']:
    for path in glob.glob(os.path.expanduser(root + '/*/SKILL.md')):
        with open(path, errors='replace') as f:
            c = f.read(4096)
        m = re.search(r'^name:\s*(\S+)', c, re.M)
        if m:
            skills.add(m.group(1).strip('\"'))

# Check skill-chains.md references
chains_path = os.path.expanduser('~/.agents/rules/skill-chains.md')
with open(chains_path) as f:
    chains_content = f.read()

refs = set(re.findall(r'`/([a-z][-a-z0-9]*)`', chains_content))
dangling = refs - skills
if dangling:
    print(f'DANGLING in skill-chains.md: {len(dangling)}')
    for d in sorted(dangling):
        print(f'  /{d}')
else:
    print('skill-chains.md: all references resolve')

# Check each SKILL.md chain section
for path in sorted(glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md'))):
    sn = os.path.basename(os.path.dirname(path))
    with open(path, errors='replace') as f:
        content = f.read()
    m = re.search(r'## Skill Chains.*?(?=\n## |\Z)', content, re.S)
    if not m: continue
    refs = set(re.findall(r'`/([a-z][-a-z0-9]*)`', m.group(0)))
    dangling = refs - skills
    if dangling:
        print(f'DANGLING in {sn}/SKILL.md: {len(dangling)}')
        for d in sorted(dangling):
            print(f'  /{d}')
" 2>&1
```

### 5. Auto-fix mode (--fix)

For each dangling reference, search for a renamed skill:
- Check if a skill with a similar name exists (fuzzy match on name)
- Check if the dangling skill was archived (`skills/_archived/`)
- If found, suggest the replacement; apply if `--fix` flag is set

## Output Format

```
chain-validate | <date>
══════════════════════════════════════════

Registry: N skills
References checked: M
Dangling: K

Findings:
  <source-file>: /<dangling-skill> (suggest: /<replacement> or DELETE)

Verdict: CLEAN | K DANGLING REFERENCES
Next: [chain-evolve] to optimize valid chains, [skill-test] to validate new skills
```

## Skill Chains

### Mandatory

None — read-only validation (unless --fix).

### Advisory

- After `[skill-merge]` → `[chain-validate]` to verify no dangling refs remain
- After `[skill-archive]` → `[chain-validate]` to verify no dangling refs remain
- Before `[skill-test]` on a new skill → `[chain-validate]` to verify chain targets exist
- After `[chain-validate]` → `[chain-evolve]` to optimize valid chains

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction (read-only); --fix requires operator approval
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
