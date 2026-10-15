---
name: identity
description: Unified HUMMBL agent identity facade — integrates design-tokens, heraldry, and garage into one AgentIdentity object. One import for full agent visual identity.
version: 0.1.0
execution-mode: advisory
argument-hint: "[agent \"agent_name\" --trust MEDIUM-HIGH --role coordinator | render \"agent_name\" --format svg]"
category: dev-tools
status: candidate
---
# HUMMBL Identity

Unified agent identity facade. Integrates `hummbl-design-tokens` (colors), `hummbl-heraldry` (arms), and `hummbl-garage` (performance/livery) into a single `AgentIdentity` object. All three dependencies are optional — degrades gracefully with fallback defaults.

## When to Use

- Getting a complete agent identity (colors + arms + performance) in one call
- Rendering agent identity for dashboards, terminals, or web
- When you need all three subsystems together (heraldry + garage + tokens)

## Usage

```bash
[identity] agent "devin" --trust MEDIUM-HIGH --role coordinator --host agent-node
[identity] render "devin" --format svg
[identity] render "devin" --format unicode
[identity] colors "devin"
```

## Python API

```python
from hummbl_identity import AgentIdentity

# Create full identity
identity = AgentIdentity(
    agent_name="devin",
    trust_tier="MEDIUM-HIGH",
    role="coordinator",
    host="delta",
)

# Access subsystems
print(identity.color)           # Design token color for this agent
print(identity.arms)            # Heraldic arms object
print(identity.api_score)       # Agent Performance Index
print(identity.livery)          # Livery preset

# Render
svg = identity.render_svg()         # Full SVG (arms + watch + gauge)
unicode_str = identity.render_unicode()  # Terminal rendering
```

## Degradation

If any subsystem is not installed, `AgentIdentity` falls back to defaults:
- No `hummbl-design-tokens` → hardcoded color palette
- No `hummbl-heraldry` → simple initial-based shield
- No `hummbl-garage` → basic status text

## Install

```bash
cd /work/active/oss/packages/python/hummbl-identity
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-identity/`
- **License**: Apache 2.0
- **Dependencies**: optional (hummbl-design-tokens, hummbl-heraldry, hummbl-garage)
