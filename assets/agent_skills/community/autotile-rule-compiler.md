---
name: autotile-rule-compiler
description: Generates 2D auto-tiling rulesets from minimal input. Supports 2x2 corner-based, 3x3 minimal (16 tiles per terrain), and 47-tile Wang sets. Outputs Godot TileSet .tres, LDtk/Tiled custom rule JSON, or Unity RuleTile configurations.
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
  pip: [numpy, pillow]
---

# Autotile Rule Compiler

Generates complete autotiling rulesets from minimal tile specifications.

## Supported Ruleset Types

| Type | Tiles | Description |
|------|-------|-------------|
| `2x2` | 4 | Corner-based (TL, TR, BL, BR) |
| `3x3` | 16×terrains | Minimal binary corner mask (TL, TR, BL, BR) |
| `wang47` | 47 | Full Wang tile set for complex terrain |

## Output Formats

| Format | Extension | Engine |
|--------|-----------|--------|
| `json` | `.json` | Generic / LDtk / Tiled |
| `godot` | `.tres` | Godot 4.x TileSet |
| `unity` | `.json` | Unity RuleTile (config) |
| `ldtk` | `.json` | LDtk custom rules |

## CLI Usage

```bash
# Dry run
python scripts/main.py --dry-run --json-output /dev/stdout

# Generate 3x3 ruleset (single terrain) as JSON
python scripts/main.py --type 3x3 --format json --output ./rules --json-output result.json

# Generate 3x3 ruleset (3 terrains) for Godot
python scripts/main.py --type 3x3 --terrains 3 --format godot --output ./tileset --json-output result.json

# Generate 2x2 corner rules for Unity
python scripts/main.py --type 2x2 --format unity --output ./ruletile --json-output result.json

# Generate Wang 47-tile set for LDtk
python scripts/main.py --type wang47 --format ldtk --output ./ldtk_rules --json-output result.json

# Docker
docker compose run --rm skill --type 3x3 --terrains 2 --format godot --output /workspace/tileset --json-output /workspace/result.json
```

## Output Schema

```json
{
  "status": "ok|error",
  "skill": "autotile-rule-compiler",
  "version": "1.0.0",
  "result": {
    "ruleset_type": "3x3",
    "terrain_types": 2,
    "tile_count": 32,
    "format": "godot",
    "output_file": "/workspace/tileset/tileset.tres"
  },
  "error": null
}
```

## Ruleset Details

### 2x2 Corner (4 tiles)
| Index | Name | Corners (TL,TR,BL,BR) |
|-------|------|----------------------|
| 0 | empty | (0,0,0,0) |
| 1 | tl_corner | (1,0,0,0) |
| 2 | tr_corner | (0,1,0,0) |
| 3 | bl_corner | (0,0,1,0) |

### 3x3 Minimal (16 tiles per terrain)
Binary corner mask: `TL TR BL BR` (bits 3,2,1,0)
- `0000` (0) = empty
- `0001` (1) = BR only
- `1111` (15) = full tile

### Wang 47-tile
Full edge-matching tileset for complex multi-terrain blending.

## Container

- **Tier**: 1 (Pure Python)
- **Base Image**: `python:3.11-slim`
- **GPU**: Not required