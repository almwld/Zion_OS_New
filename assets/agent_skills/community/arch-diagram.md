---
name: arch-diagram
description: Generate interactive architecture diagrams as self-contained HTML/SVG files.
version: 0.1.0
execution-mode: advisory
argument-hint: <component or system to diagram>
category: dev-tools
status: candidate
---
# Architecture Diagram Command

Generate a self-contained HTML file with an interactive SVG architecture diagram.

## Usage

```bash
[arch-diagram] briefing pipeline      # Morning Briefing data flow
[arch-diagram] adapter ecosystem      # All 7 adapters and their connections
[arch-diagram] idp delegation         # IDP delegation token flow
[arch-diagram] full system            # Complete system architecture
```

## Execution

### 1. Research the component
Read relevant source files to understand:
- Components and their relationships
- Data flow direction
- External dependencies
- Trust boundaries

### 2. Generate HTML
Create a self-contained HTML file with:
- Inline SVG diagram (no external dependencies)
- Inline CSS for styling
- Inline JavaScript for interactivity (collapse/expand, hover details)
- Color coding: green=healthy, yellow=degraded, red=down, gray=disabled
- Arrows showing data flow direction

### 3. Write and open
```bash
# Write to /tmp/arch-<name>.html
open /tmp/arch-<name>.html
```

## Diagram Elements

### Components
- **Services**: rounded rectangles (blue border)
- **Integrations/Adapters**: rectangles (green border)
- **External Services**: dashed rectangles (gray border)
- **Data Stores**: cylinders (orange border)
- **Bus/Queue**: parallelogram (purple border)

### Connections
- Solid arrow: synchronous call
- Dashed arrow: async / event-driven
- Thick arrow: high-frequency data path
- Red arrow: error/failure path

### Layout
- Top-down for pipelines
- Left-to-right for data flow
- Grouped by layer (external > integration > service > storage)

## Output Format

The HTML file should:
- Be viewable in any browser
- Have a title bar with component name and generation timestamp
- Include a legend explaining colors and shapes
- Support click-to-expand on component groups
- Be under 500 lines of HTML

After generation, report:
```
Diagram generated: /tmp/arch-<name>.html
Components: N nodes, M connections
Opening in browser...
```

## Constraints

- Self-contained HTML only -- no external CDN, frameworks, or dependencies.
- Diagrams must reflect actual code structure, not hypothetical architecture.
- Read source files before diagramming -- do not diagram from memory.
- Keep diagrams focused: max ~20 nodes per diagram. Suggest splitting if larger.
