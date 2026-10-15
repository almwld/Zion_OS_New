---
name: ldtk-type-generator
description: Parses .ldtk project files and auto-generates type-safe structs/classes for all entity fields, level identifiers, and custom enum definitions. Supports Godot (GDScript), Unity (C#), and TypeScript output.
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

# LDtk Type Generator

Parses LDtk (Level Designer Toolkit) project files and generates type-safe code for game engines.

## Features

- **Enums** - Extracts custom enum definitions with values
- **Entities** - Generates typed classes/structs for all entity definitions with field types
- **Levels** - Outputs level identifiers and world coordinates
- **Multi-target** - Godot (GDScript), Unity (C#), TypeScript

## Supported LDtk Elements

| Element | Extracted |
|---------|-----------|
| Enums | Identifier, values, doc |
| Entity Defs | Fields (name, type, required, default, doc) |
| Levels | Identifier, UID, world coordinates, dimensions |

## CLI Usage

```bash
# Dry run
python scripts/main.py --dry-run --json-output /dev/stdout

# Generate Godot GDScript
python scripts/main.py --input project.ldtk --engine godot --output ./generated --json-output result.json

# Generate Unity C#
python scripts/main.py --input project.ldtk --engine unity --output ./Assets/Scripts/LDtk --json-output result.json

# Generate TypeScript
python scripts/main.py --input project.ldtk --engine typescript --output ./src/types --json-output result.json

# Docker
docker compose run --rm skill --input /workspace/project.ldtk --engine godot --output /workspace/generated --json-output /workspace/result.json
```

## Output Examples

### Godot GDScript
```gdscript
enum EnemyType:
    GOBLIN = "goblin"
    ORC = "orc"
    DRAGON = "dragon"

class Enemy:
    var name: String
    var health: int = 100
    var enemy_type: EnemyType
    var is_boss?: bool = false
```

### Unity C#
```csharp
public enum EnemyType { Goblin, Orc, Dragon }

[Serializable]
public class Enemy {
    public string name;
    public int health = 100;
    public EnemyType enemy_type;
    public bool is_boss = false;
}
```

### TypeScript
```typescript
export enum EnemyType { Goblin = "goblin", Orc = "orc", Dragon = "dragon" }

export interface Enemy {
    name: string;
    health: number;
    enemy_type: EnemyType;
    is_boss?: boolean;
}
```

## Container

- **Tier**: 1 (Pure Python)
- **Base Image**: `python:3.11-slim`
- **GPU**: Not required