---
name: bus-audit
description: Parse the fleet bus TSV and produce a Rumsfeldian epistemological map -- known knowns, known unknowns, unknown knowns, and unknown unknowns -- from bus message tags.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--bus PATH] [--output PATH]"
status: candidate
schema_version: 0.1.0
category: fleet-ops
---
# Bus Audit -- Rumsfeldian Epistemological Map

## Mandatory

- Run [crab] before consequential work; verify the current lane, shared state and authorized scope.
- Resolve the canonical bus source and record its refresh time and analysis window. Treat any TSV cache as read-only evidence, not a write target or proof of current fleet state.
- Verify bus_tags.py and the map template exist at the resolved skill location; choose an output path that preserves existing reports. Redact credential values before writing extracted messages.

## Authority

The side_effecting classification grants no permission by itself. Apply current operator scope, canonical roster, trust/AIP, budget, data and protected-surface rules. These boundaries take precedence over conflicting legacy examples below; preserve stricter applicable restrictions. Reuse authorization already established for the task.

May read the scoped bus snapshot and write the requested inventory/report. It does not authorize changes to bus history, agent status, message taxonomy, or unrelated paths. Post any authorized receipt through the canonical bus writer under the invoking agent's verified identity.

Parse the global bus TSV (`~/.cache/bus/messages.tsv`) and extract every
pattern-matchable tag, then produce a four-quadrant epistemological map of
what the fleet knows, doesn't know, knows without knowing, and can't know
it doesn't know.

## When to Use

- Operator asks "what does the bus know?" or "audit the bus"
- Fleet health / observability review -- what signals are we emitting?
- Epistemological audit -- what's the gap between tagged and tacit knowledge?
- Pre-governance review -- identify missing tags, silent agents, untagged patterns
- When user says "bus audit", "rumsfeldian map", "bus tag inventory", or "what don't we know"

## Execution

1. **Run the parser** to extract the tag inventory:
   ```bash
   python bus_tags.py --bus ~/.cache/bus/messages.tsv --output bus_tag_inventory.json
   ```
   This produces a structured JSON inventory of all explicit tags, entity
   references, signal tags, gap markers, absence markers, top words, and
   bigrams.

2. **Read the inventory** (`bus_tag_inventory.json`) and classify every
   extracted signal into one of four Rumsfeldian quadrants:

   | | **Known** | **Unknown** |
   |---|---|---|
   | **Known** | Known knowns -- explicitly tagged, counted, understood | Known unknowns -- gaps we've named but not filled |
   | **Unknown** | Unknown knowns -- tacit patterns we emit but don't tag | Unknown unknowns -- absences invisible from inside the bus |

3. **Produce the map** using `rumsfeldian_map_template.md` as the scaffold.
   Fill each quadrant with findings from the inventory, citing exact counts.

4. **Surface meta-unknowns**: Note patterns the analysis itself may have
   missed. The map is bounded by the patterns the parser knew to look for.

## Output Format

```
Bus Audit | Rumsfeldian Map | {date_range}
==========================================

Source: {N} messages on {bus_path}
Inventory: bus_tag_inventory.json ({size})
Parser: bus_tags.py

## I. Known Knowns
  [message taxonomy, agent identity, topology, bracket tags, skills,
   lanes, hosts, doctrines, primitives, entity refs, severity signals]

## II. Known Unknowns
  [gap markers, absence markers, named unknowns -- surface=unknown,
   cogstate=NOT_DECLARED, host=unknown, etc.]

## III. Unknown Knowns
  [tacit topology, power-law concentration, temporal patterns, failure
   signatures, decay signals, file-type hierarchy, bigram patterns,
   cogstate defaults, model stratification, doctrine concentration]

## IV. Unknown Unknowns
  [silent agents, silent failures, operator mind, duration gaps, cost
   gaps, quality gaps, causal chains, agent internal state, external
   events, bus self-health, skill success rates, dependency graphs,
   one-shot vocabulary, args_hash opacity]

## V. Summary Matrix
  [quadrant x tag count x signal density x epistemic status]

## VI. Meta-Unknown
  [what this analysis itself cannot see]
```

## Files

- `bus_tags.py` -- Parameterized TSV parser. Accepts `--bus` and `--output`
  flags. Extracts bracket tags, key=value tags, skills, lanes, hosts,
  machines, surfaces, cogstates, intents, phases, doctrines, primitives,
  PRs, commits, issues, repos, URLs, file paths, severity, gap markers,
  absence markers, top words, bigrams, and tag co-occurrence.
- `rumsfeldian_map_template.md` -- Scaffold for the four-quadrant map output.
- `README.md` -- Explains the four quadrants and how to interpret results.

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Tag inventory produced | `[governance-report]` to formalize findings |
| Gap markers identified | `[gap-analysis]` for remediation prioritization |
| Silent agents found | `[ops]` to investigate dormant agent connections |
| Tacit patterns surfaced | `[govern]` to propose new bus tag vocabulary |
| Unknown unknowns listed | `[ai-risk-assessment]` to score epistemic blind spots |

## Privacy Gate

This skill reads bus messages which may contain file paths, commit hashes,
and operational details.
- **Do not** log or output secrets, tokens, or credentials found in messages.
- **Redact** any credential values that appear in the inventory.
- **Scope** access to the bus TSV only; do not traverse unrelated paths.
