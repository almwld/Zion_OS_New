---
name: polycube-lab
description: "Compose, decompose, validate, and audit face-connected lattice polycubes, including labeled epistemic models. Use when 3-D adjacency, topology, symmetry, slicing, packing, or reconfiguration is decision-relevant; use uncertainty-map for an ordinary four-quadrant uncertainty map."
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<model or input path> [--mode geometry|packing|reconfiguration|epistemic|render]"
category: fleet-ops
status: candidate
providers:
  required: [python]
---

# Polycube Lab

Model a system as a connected set of unit cells only when the geometry carries
defined meaning. A polycube is not a decorative stack of matrices.

## Model Contract

Before analysis, state:

1. **Cell meaning** — what one occupied cube represents.
2. **Coordinate meaning** — what each axis represents and whether its values are
   genuinely ordered.
3. **Adjacency meaning** — what sharing a full face permits or implies.
4. **Equivalence** — whether translation, proper rotation, or reflection may be
   treated as the same design.
5. **Move model** — for assembly or reconfiguration, define allowed slides,
   pivots, detachments, helpers, and collision rules.
6. **Absence meaning** — distinguish `impossible`, `forbidden`, `unobserved`,
   `unknown`, and `missing`; an empty coordinate is otherwise ambiguous.

If arbitrary categories have no natural spatial ordering, use a labeled product
graph instead. If the problem is all combinations of independent binary
variables, use a hypercube. If disconnected occupancy is allowed, call it a
voxel set rather than a polycube.

## Representation

Represent ordinary geometry as integer coordinates with six-neighbor face
connectivity:

```json
{
  "cells": [[0, 0, 0], [1, 0, 0], [1, 1, 0]],
  "equivalence": "rotation",
  "move_model": "static"
}
```

For labeled or epistemic models, a cell may instead be an object:

```json
{
  "model_contract": {
    "cell_meaning": "one decision-relevant claim state",
    "adjacency_meaning": "one permitted single-axis transition",
    "absence_meaning": "a classified state outside active occupancy",
    "equivalence": "none",
    "move_model": "state-transition"
  },
  "axes": [
    {
      "name": "meta_level",
      "meaning": "level of representation being assessed",
      "ordered": true,
      "values": {"0": "claim", "1": "assessment"}
    },
    {
      "name": "review_stage",
      "meaning": "current decision-review stage",
      "ordered": true,
      "values": {"0": "intake"}
    },
    {
      "name": "evidence_threshold",
      "meaning": "minimum admitted evidence grade",
      "ordered": true,
      "values": {"0": "unverified"}
    }
  ],
  "cells": [
    {
      "coord": [0, 0, 0],
      "kind": "claim",
      "quadrant": "known_unknown",
      "evidence_basis": "unverified",
      "freshness": "not-applicable",
      "confidence": "medium",
      "evidence_refs": []
    }
  ],
  "bounds": {"min": [0, 0, 0], "max": [1, 0, 0]},
  "absence_codes": {"1,0,0": "unobserved"}
}
```

Keep geometry and metadata separate: coordinates encode the spatial contract;
labels encode provenance, state, authority, risk, confidence, or ownership.

## Modes

### Geometry

Validate face connectivity and calculate unit count, shared faces, exposed
surface, bounding box, slices, symmetries, articulation cells, and enclosed
cavities. Do not infer physical stability from connectivity.

### Packing

Define the target cells, piece identities, allowed orientations, reflection
policy, and whether every target must be covered exactly once. Perfect finite
packing can be formulated as exact cover. Use set cover, multicover, SAT, CP,
or MILP when overlap, redundancy, capacities, costs, or logical constraints are
part of the problem.

### Reconfiguration

Treat configurations as nodes and legal moves as edges. Report a construction
or transformation path only under the stated move model. A path valid for
sliding cubes is not evidence that pivots, magnets, robots, or gravity permit it.

### Epistemic

Use cells for decision-relevant claims, uncertainties, obligations, or review
states. Prefer ordered axes such as representational level, lifecycle stage, or
evidence threshold; keep Rumsfeld quadrant, evidence basis, freshness,
confidence, observer, and provenance as labels unless their spatial ordering is
explicitly justified.

Useful queries include:

- disconnected components as possible silos;
- articulation cells as dependency or review bottlenecks;
- uncoded empty coordinates as ambiguous coverage gaps;
- shortest legal paths as candidate uncertainty-reduction sequences;
- slices as ordinary matrices or reports;
- shape diffs as reclassification or evidence drift.

These interpretations are conditional on the model contract. A graph cycle is
not automatically a geometric tunnel, and a cavity is not automatically a blind
spot.

## Workflow

1. Define the model contract and analysis boundary.
2. Normalize coordinates and declare the symmetry policy.
3. Validate duplicates, integer coordinates, and face connectivity.
4. Run only the analyses that change the decision.
5. Separate computed facts from semantic interpretations.
6. For every proposed composition or decomposition, state preserved and changed
   invariants.
7. End with the smallest next experiment, probe, or transformation that would
   validate the model.

For deterministic coordinate checks, use `scripts/polycube.py` when available
instead of manually recounting adjacency, surface, cavities, or articulation
cells.

### Representation routing

Use `route` before committing to a 3-D surface. It routes by observed occupancy,
not by the mere presence of three coordinate slots or three declared axes:

1. Auditable contract, label, or absence defects surfaced by a successful
   route require `model_contract_repair`. The result also reports the
   provisional route under the currently declared non-hard routing signals;
   repairs may change it. Structurally malformed core bounds or absence
   containers are rejected before routing.
2. An explicitly unordered semantic axis requires a `product_graph`; the tool
   does not invent categorical edges.
3. Disconnected face occupancy is a `voxel_set`, not a polycube.
4. Connected point, linear, planar, and volumetric occupancy routes to the
   smallest faithful surface: coordinate table or table, path graph or table,
   polyomino, then polycube.

The router reports internal representation fitness. It does not prove that an
epistemic model contract is externally true, that adjacency is causally valid,
or that a geometric model is physically realizable.

### Offline workbench

Use `render` to write a deterministic, dependency-free HTML workbench. Python
remains the geometry authority; the Canvas view only projects its computed
cells, articulation points, and cavity results. The artifact includes native
HTML controls, keyboard alternatives, an accessible workbench summary,
reduced-motion behavior, and a restrictive no-network content security policy.

Cavity cells are highlighted only when the complete bounded cell set is
available. Larger cavities render dashed bounds, identified by the workbench
controls and legend, rather than a partial sample that could be mistaken for
exact membership. `render` accepts occupied-cell source coordinates only in
JavaScript's safe integer range, `[-(2^53 - 1), 2^53 - 1]`; accepted occupied
cell coordinates remain visible while Canvas calculations use a safe local
origin.

Rendering never opens a browser automatically. It refuses to replace an
existing file unless `--force` is explicit, writes through a same-directory
temporary file, and publishes no-force outputs without an overwrite race.

### Platform invocation

The kernel uses only the Python standard library. On Windows (PowerShell), use
`python`; on Unix (bash), use `python3` if `python` is not mapped to Python 3.
The examples below use `python`; substitute the available Python 3 launcher.

```bash
python scripts/polycube.py analyze shape.json --pretty
python scripts/polycube.py canonicalize shape.json --pretty
python scripts/polycube.py epistemic-audit model.json --strict --pretty
python scripts/polycube.py route model.json --pretty
python scripts/polycube.py render shape.json --output workbench.html
```

`model_valid` means the declared schema and topology are internally valid. Also
inspect `spatial_fit`: a valid line or plane embedded in three dimensions may be
clearer as a table, polyomino, or product graph.

`recommended_representation` is the router decision. When it is
`model_contract_repair`, inspect `hard_issue_codes` and
`provisional_representation` before changing the model. The generated workbench
is a local exploratory artifact, not evidence of semantic truth, structural
safety, manufacturability, or robotic feasibility.

## Execution Controls

### Mandatory

- Establish the model contract, input boundary, and requested mode before
  invoking the kernel. Return a clarification rather than inventing axes,
  adjacency, equivalence, or a move model.
- Treat analysis modes as read-only. `render` requires an explicit output path
  and may only create a new local artifact requested by the user or an
  authorized delegated task.
- Do not use `--force` to replace an existing workbench without explicit
  operator authorization. Do not open a browser, publish the artifact, or
  transmit model data as part of this skill.

## Authority

- **T1 (TRUSTED):** May run read-only analysis. May render to a
  named, new local path when the invocation explicitly requests that artifact.
- **T2 (Active/High):** May run read-only analysis. May render to a named, new
  local path when the invocation explicitly requests that artifact.
- **T3:** Read-only analysis only; operator approval is required before
  rendering.
- **T4:** Read-only analysis only; may not render or overwrite artifacts.
- **Operator:** May authorize an overwrite or any broader artifact handling.

## Output

```markdown
Polycube Lab | <topic> | <mode>

## Decision Readout
- Safe to conclude: <computed or evidenced result>
- Conditional interpretation: <depends on model contract>
- Highest-value next operation: <probe, cut, glue, slice, solve, or remap>

## Model Contract
| Element | Definition |
|---|---|
| Cell | ... |
| Axes | ... |
| Shared face | ... |
| Absence | ... |
| Equivalence / moves | ... |

## Computed Structure
<metrics, components, articulation cells, cavities, slices, or placements>

## Composition / Decomposition Options
<operations, preserved invariants, trade-offs>

## Semantic Audit
<unsupported adjacency, ambiguous blanks, lossy projections, missing labels>
```

## Boundaries

- Use `uncertainty-map` when a four-quadrant decision map is sufficient and no
  spatial or topological query matters.
- Use `knowledge-map` for who-knows-what and bus-factor analysis.
- Use `concept-map` for general dependency graphs without lattice semantics.
- Use a cubical-complex or persistent-homology tool when rigorous tunnels,
  cavities across thresholds, or dimensions above three are required.
- Do not claim manufacturability, structural safety, or robotic feasibility
  without the corresponding physical constraints and evidence.
