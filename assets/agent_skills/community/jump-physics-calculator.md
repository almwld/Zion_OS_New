---
name: jump-physics-calculator
description: Calculates exact kinematic formulas (gravity, jump velocity, coyote time, air control) from designer values (jump height, apex duration). Generates plug-and-play controller code for Godot, Unity, Unreal, or custom C++.
version: 1.0.0
execution-mode: advisory
container:
  tier: "1"
  base_image: "python:3.11-slim"
  gpu: false
category: dev-tools
status: candidate
providers:
  required: [docker, pytest, python, uv]
---

# Jump Physics Calculator

Translates intuitive designer values into exact physics constants for character controllers.

## Formulas

- **Jump Gravity (upward)**: `g_up = 2h / t_apex²`
- **Initial Jump Velocity**: `v₀ = 2h / t_apex`
- **Fall Gravity**: `g_down = 2h / (t_apex × fall_multiplier)²`
- **Total Air Time**: `t_apex + t_apex × fall_multiplier`

## CLI Usage

```bash
# Dry run
python scripts/main.py --dry-run --json-output /dev/stdout

# Calculate physics (default: Godot)
python scripts/main.py --height 3.0 --time-to-apex 0.5 --json-output result.json

# Unity C# output
python scripts/main.py --height 3.0 --time-to-apex 0.5 --engine unity --json-output result.json

# Custom fall multiplier (snappy descent)
python scripts/main.py --height 3.0 --time-to-apex 0.5 --fall-multiplier 0.7 --json-output result.json

# Docker
docker compose run --rm skill --height 3.0 --time-to-apex 0.5 --json-output /workspace/result.json
```

## Output Schema

```json
{
  "status": "ok|error",
  "skill": "jump-physics-calculator",
  "version": "1.0.0",
  "result": {
    "physics": {
      "jump_gravity_up": 24.0,
      "initial_velocity": 12.0,
      "fall_gravity": 24.0,
      "time_to_apex": 0.5,
      "time_to_fall": 0.5,
      "total_air_time": 1.0,
      "terminal_velocity": 18.0,
      "height": 3.0,
      "fall_time_multiplier": 1.0
    },
    "controller_code": "# Godot 4.x CharacterBody2D Jump Controller...\n",
    "engine": "godot"
  },
  "error": null
}
```

## Example Outputs

| Height | Time to Apex | g_up | v₀ | Engine |
|--------|-------------|------|-----|--------|
| 3.0 | 0.5 | 24.0 | 12.0 | Godot/Unity |
| 4.0 | 0.6 | 22.2 | 13.3 | Godot/Unity |
| 2.5 | 0.4 | 31.25 | 12.5 | Godot/Unity |

## Container

- **Tier**: 1 (Pure Python)
- **Base Image**: `python:3.11-slim`
- **GPU**: Not required
- **Volumes**: Workspace (RW), Cache (RO), Config (RO)