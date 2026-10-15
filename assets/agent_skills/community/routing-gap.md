---
name: routing-gap
description: Find skills with no routing entries in skill-routing.md, and routing entries pointing to skills that don't exist. Detects invisible skills and phantom routes.
version: 0.1.0
execution-mode: advisory
argument-hint: "[orphans | phantoms | full]"
category: hummbl-research
status: candidate
providers:
  required: [python]
---
# routing-gap

Cross-reference the skill registry against `skill-routing.md` to find:
1. **Orphans**: skills that exist on disk but have no routing trigger (invisible to agents)
2. **Phantoms**: routing entries pointing to skills that don't exist (dead routes)

## When to Use

- After creating new skills (verify they're routable)
- After `[skill-merge]` or `[skill-archive]` (verify routing was updated)
- Periodic health check (pair with `[routing-evolve]`)
- When a skill seems impossible to trigger via natural language

## Usage

```bash
[routing-gap]              # Full report: orphans + phantoms
[routing-gap] orphans      # Skills with no routing triggers
[routing-gap] phantoms     # Routing entries pointing to missing skills
```

## Execution

### 1. Build skill registry

```bash
cd $HOME && python3 -c "
import os, re, glob
skills = set()
for root in ['~/.agents/skills', '~/.agents/skills-full']:
    for path in glob.glob(os.path.expanduser(root + '/*/SKILL.md')):
        with open(path, errors='replace') as f:
            c = f.read(4096)
        m = re.search(r'^name:\s*(\S+)', c, re.M)
        if m:
            skills.add(m.group(1).strip('\"'))
print('\n'.join(sorted(skills)))
" > /tmp/skill_registry.txt
wc -l /tmp/skill_registry.txt
```

### 2. Parse routing targets

```bash
cd $HOME && python3 -c "
import os, re
routing_path = os.path.expanduser('~/.agents/skill-routing.md')
with open(routing_path) as f:
    content = f.read()
# Extract target skill names from routing entries: -> /skill-name
targets = set(re.findall(r'->\s*/([a-z][-a-z0-9]*)', content))
# Also catch legacy alias format
targets |= set(re.findall(r'legacy alias:\s*/([a-z][-a-z0-9]*)', content))
print('\n'.join(sorted(targets)))
" > /tmp/routing_targets.txt
wc -l /tmp/routing_targets.txt
```

### 3. Find orphans (skills with no routing)

```bash
comm -23 /tmp/skill_registry.txt /tmp/routing_targets.txt
```

### 4. Find phantoms (routing to missing skills)

```bash
comm -13 /tmp/skill_registry.txt /tmp/routing_targets.txt
```

### 5. Classify orphans

For each orphan, check if it has a description that should be routable:
- If the SKILL.md has a good description → routing gap (add triggers)
- If the skill is a sub-component or internal helper → expected (no routing needed)
- If the skill is deprecated/merged → expected (stub should be cleaned up)

### 6. Classify phantoms

For each phantom, check:
- Was the skill recently renamed? Search for similar names in the registry
- Was it archived? Check `skills/_archived/`
- Was it merged? Check for MERGED stubs

## Output Format

```
routing-gap | <date>
══════════════════════════════════════════

Registry: N skills | Routing targets: M

Orphans (no routing — invisible to agents): K
  <skill-name> — <description first 60 chars>
  ...

Phantoms (routing to missing skills): J
  /<phantom-skill> — <suggested replacement or DELETE>
  ...

Verdict: CLEAN | K ORPHANS, J PHANTOMS
Next: [routing-evolve] to add missing triggers, [skill-demote] to clean up phantoms
```

## Skill Chains

### Mandatory

None — read-only analysis.

### Advisory

- After `[skill-create]` → `[routing-gap]` to verify the new skill is routable
- After `[skill-merge]` → `[routing-gap]` to verify old routes were updated
- After `[skill-archive]` → `[routing-gap]` to verify routes were removed
- After `[routing-gap]` → `[routing-evolve]` to add missing triggers
- After `[routing-gap]` → `[skill-demote]` to clean up phantom targets

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: May run without restriction
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
