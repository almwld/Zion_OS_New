---
name: dependency-graph
description: Map module dependencies, find circular imports, calculate coupling metrics.
version: 0.1.0
execution-mode: advisory
argument-hint: <package or directory to analyze>
category: dev-tools
status: candidate
---
# Dependency Graph

Analyze import relationships between modules to find circular dependencies, tight coupling, and architecture violations.

## Execution

### 1. Build the import graph
```bash
python3 -c "
import ast, json
from pathlib import Path
from collections import defaultdict

target = '${TARGET:-services}'
graph = defaultdict(set)

for f in sorted(Path(target).rglob('*.py')):
    if '.venv' in str(f) or '__pycache__' in str(f): continue
    module = str(f).replace('/', '.').replace('.py', '')
    try:
        tree = ast.parse(f.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom) and node.module:
                if node.module.startswith('your_project'):
                    graph[module].add(node.module)
            elif isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name.startswith('your_project'):
                        graph[module].add(alias.name)
    except: pass

# Print edges
for src, deps in sorted(graph.items()):
    for dep in sorted(deps):
        print(f'{src} -> {dep}')
"
```

### 2. Find circular dependencies
```bash
python3 -c "
# DFS cycle detection on the import graph
# (uses graph built above)
from collections import defaultdict

graph = defaultdict(set)
# ... build graph same as above ...

def find_cycles(graph):
    visited = set()
    path = set()
    cycles = []

    def dfs(node, current_path):
        visited.add(node)
        path.add(node)
        current_path.append(node)
        for neighbor in graph.get(node, []):
            if neighbor in path:
                cycle_start = current_path.index(neighbor)
                cycles.append(current_path[cycle_start:] + [neighbor])
            elif neighbor not in visited:
                dfs(neighbor, current_path)
        path.remove(node)
        current_path.pop()

    for node in graph:
        if node not in visited:
            dfs(node, [])
    return cycles
"
```

### 3. Calculate coupling metrics

| Metric | Description |
|--------|-------------|
| **Fan-out** | How many modules does X import? (high = depends on many things) |
| **Fan-in** | How many modules import X? (high = many things depend on it) |
| **Instability** | Fan-out / (Fan-in + Fan-out). 0=stable, 1=unstable |
| **Coupling score** | Total edges in the graph / total modules |

### 4. Identify architecture violations
- Does `integrations/` import from `services/`? (should be the reverse)
- Does `bus/` import from `cognition/`? (should be independent)
- Does `tests/` import from `_state/`? (should use fixtures)

## Output Format
```
Dependency Graph | <target>
════════════════════════════

## Graph (N modules, M edges)
<top importers and most-imported>

## Circular Dependencies
<list or "None found">

## Coupling Metrics
| Module | Fan-in | Fan-out | Instability |
|--------|--------|---------|-------------|

## Architecture Violations
<layer boundary crossings>

## Recommendations
1. <break cycle by extracting interface>
2. <reduce fan-out by consolidating imports>
```

## Base120 Context
- Primary: **DE3** (Modularization)
- Related: **CO8** (Layered Abstraction), **SY2** (System Boundaries)
