---
name: heraldry
description: Generate heraldic arms for HUMMBL agents — SVG shields, Unicode renderings, blazon text from agent name + trust tier + role.
version: 0.1.0
execution-mode: advisory
argument-hint: "[generate \"agent_name\" --trust MEDIUM-HIGH --role coordinator | svg \"agent_name\" | unicode \"agent_name\" | blazon \"agent_name\"]"
category: dev-tools
status: candidate
---
# HUMMBL Heraldry

Procedural heraldic identity system. Generates deterministic heraldic arms from agent names using SHA-256. Each agent gets a unique shield with tinctures, divisions, ordinaries, and charges.

## When to Use

- Generating visual identity for a new agent
- Rendering agent shields in terminal (Unicode) or web (SVG)
- Getting blazon text (heraldic description) for an agent
- Creating fleet identity assets

## Usage

```bash
[heraldry] generate "devin" --trust MEDIUM-HIGH --role coordinator --host agent-node
[heraldry] svg "devin" --width 120 --height 144
[heraldry] unicode "devin"
[heraldry] blazon "devin"
[heraldry] list-agents
```

## Python API

```python
from hummbl_heraldry import ArmsGenerator, Grammar

gen = ArmsGenerator(grammar=Grammar())
arms = gen.generate(
    agent_name="devin",
    trust_tier="MEDIUM-HIGH",
    role="coordinator",
    host="delta"
)

# SVG rendering
from hummbl_heraldry.svg import render_arms_svg
svg = render_arms_svg(arms, width=120, height=144)

# Unicode terminal rendering
from hummbl_heraldry.text import render_arms_unicode, render_arms_compact
unicode_str = render_arms_unicode(arms)
compact = render_arms_compact(arms)

# Blazon text (heraldic description)
print(arms.blazon)
```

## Key Concepts

- **7-layer identity system**: Layer 0 (fleet/host) → Layer 1 (base arms from SHA-256) → Layer 2 (trust tier cadency) → Layer 3 (role badge) → Layer 4 (host patch) → Layer 5 (skill tabs) → Layer 6 (runtime status)
- **Deterministic**: Same agent name always produces the same arms
- **Tinctures**: Uses traditional heraldic tincture rules (metal on color, color on metal)
- **Trust tiers**: Affects cadency mark — higher trust = more prominent mark

## Install

```bash
cd /work/active/oss/packages/python/hummbl-heraldry
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-heraldry/`
- **License**: Apache 2.0
- **Dependencies**: stdlib only
