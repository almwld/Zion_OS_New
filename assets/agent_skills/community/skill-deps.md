---
name: skill-deps
description: Check if scripts, references, and assets referenced in SKILL.md actually exist on disk. Catches broken paths after moves, renames, or partial syncs.
version: 0.1.0
execution-mode: advisory
argument-hint: "[<skill-name>] [--fix]"
category: hummbl-research
status: candidate
---
# skill-deps

Scan SKILL.md files for filesystem references — scripts, reference docs,
assets, and external paths — and verify each one exists on disk. Broken
references happen after directory moves, partial syncs, or when bundled
files are deleted without updating the SKILL.md.

## When to Use

- After `[skill-create]` to verify all referenced paths exist
- After a fleet sync or mesh migration to catch broken paths
- When a skill fails at runtime with "file not found"
- Periodic health check (pair with `[skill-test]`)
- Before promoting a skill from candidate to tested

## Usage

```bash
[skill-deps]                # Check all skills
[skill-deps] <skill-name>   # Check one skill
[skill-deps] --fix          # Attempt to locate missing files via fuzzy search
```

## Execution

### 1. Extract path references from SKILL.md

Scan for these patterns in each SKILL.md:
- `~/.agents/skills/<name>/scripts/...`
- `~/.agents/skills/<name>/references/...`
- `~/.agents/skills/<name>/assets/...`
- `~/.agents/skills/<name>/agents/...`
- `$HOME/.agents/skills/<name>/...`
- `python3 ~/.agents/skills/<name>/...`
- Relative paths within the skill directory

```bash
cd $HOME && python3 -c "
import os, re, glob

ref_patterns = [
    re.compile(r'~/\.agents/skills/[\w-]+/(?:scripts|references|assets|agents)/[\w./-]+'),
    re.compile(r'\$HOME/\.agents/skills/[\w-]+/(?:scripts|references|assets|agents)/[\w./-]+'),
    re.compile(r'python3?\s+~/\.agents/skills/[\w-]+/[\w./-]+'),
    re.compile(r'python3?\s+\$HOME/\.agents/skills/[\w-]+/[\w./-]+'),
]

for path in sorted(glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md'))):
    skill_name = os.path.basename(os.path.dirname(path))
    with open(path, errors='replace') as f:
        content = f.read()
    refs = set()
    for pat in ref_patterns:
        for m in pat.finditer(content):
            ref = m.group(0).replace('\$HOME', os.path.expanduser('~')).replace('~', os.path.expanduser('~'))
            # Extract just the file path
            path_match = re.search(r'(/\.agents/skills/[\w-]+/[\w./-]+)', ref)
            if path_match:
                full = os.path.expanduser('~') + path_match.group(1)
                refs.add(full)
    for ref in sorted(refs):
        exists = os.path.exists(ref)
        status = 'OK' if exists else 'MISSING'
        print(f'{status}\t{skill_name}\t{ref}')
" 2>&1
```

### 2. Check skill directory structure

For each skill, verify expected directories exist if referenced:
```bash
for skill_dir in scripts references assets agents; do
  [ -d ~/.agents/skills/<name>/$skill_dir ] && echo "OK: $skill_dir/" || echo "MISSING: $skill_dir/"
done
```

### 3. Check for orphaned files (files on disk not referenced in SKILL.md)

```bash
cd $HOME && python3 -c "
import os, re, glob

for path in sorted(glob.glob(os.path.expanduser('~/.agents/skills/*/SKILL.md'))):
    skill_name = os.path.basename(os.path.dirname(path))
    skill_dir = os.path.dirname(path)
    with open(path, errors='replace') as f:
        content = f.read()
    # Find all files in subdirectories
    for sub in ['scripts', 'references', 'assets', 'agents']:
        sub_path = os.path.join(skill_dir, sub)
        if not os.path.isdir(sub_path):
            continue
        for root, _, files in os.walk(sub_path):
            for fname in files:
                fpath = os.path.join(root, fname)
                rel = os.path.relpath(fpath, skill_dir)
                if rel not in content:
                    print(f'ORPHANED\t{skill_name}\t{rel}')
" 2>&1
```

### 4. Auto-fix mode (--fix)

For each missing file:
- Search the skill directory for similarly-named files (fuzzy match)
- Search `skills/_archived/` for the file
- If found, suggest updating the SKILL.md reference or restoring the file

## Output Format

```
skill-deps | <date>
══════════════════════════════════════════

Skills checked: N
References verified: M
Missing files: K
Orphaned files: J

Missing:
  <skill-name>: <path> (suggest: <fix>)

Orphaned:
  <skill-name>: <file> (not referenced in SKILL.md)

Verdict: CLEAN | K MISSING, J ORPHANED
Next: [skill-test] for full validation, [skill-audit] for security review
```

## Skill Chains

### Mandatory

None — read-only analysis (unless --fix).

### Advisory

- After `[skill-create]` → `[skill-deps]` to verify all paths resolve
- After `[skill-merge]` → `[skill-deps]` to verify copied files are referenced
- After fleet sync → `[skill-deps]` to catch broken paths
- After `[skill-deps]` → `[skill-test]` for full validation
- After `[skill-deps]` → `[skill-audit]` for security review of bundled files

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction (read-only); --fix requires operator approval
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
