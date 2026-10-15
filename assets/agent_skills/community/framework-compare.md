---
name: framework-compare
description: Compare two governance frameworks side-by-side with control overlap analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "<framework1> <framework2> [--output matrix|narrative]"
category: governance-compliance
status: candidate
---
# Framework Compare

Compare two governance frameworks side-by-side: control overlap, unique requirements, and migration effort. Useful for organizations mapping between compliance standards or evaluating which frameworks to adopt.

## When to Use
- Client needs to comply with multiple frameworks simultaneously
- Evaluating whether to add a new framework to existing compliance program
- Mapping controls between standards for crosswalk documentation
- Estimating effort to extend compliance from one framework to another

## Execution
1. Parse `$ARGUMENTS` for `<framework1>` (required), `<framework2>` (required), and `--output` (default: `matrix`)
2. Supported frameworks (extensible): NIST AI RMF, NIST CSF, ISO 27001, ISO 42001, SOC 2, GDPR, EU AI Act, OWASP AI, MITRE ATLAS
3. For each framework:
   a. Load control catalog (from `contracts/governance/` or built-in knowledge)
   b. Enumerate control domains and individual controls
   c. Identify control objectives and evidence requirements
4. Compare:
   a. **Overlap**: controls in both frameworks addressing the same risk (map by objective)
   b. **Unique to F1**: requirements only in framework 1
   c. **Unique to F2**: requirements only in framework 2
   d. **Conflicts**: areas where frameworks have contradictory requirements
5. Estimate migration effort:
   - Already covered (overlap): no additional work
   - Gap controls: estimate effort per control (low/medium/high)
   - Total incremental effort to add F2 given F1 compliance
6. If `--output matrix`: render as a control-by-control mapping table
7. If `--output narrative`: render as prose with sections for each domain

## Output Format
```
Framework Compare | {framework1} vs {framework2}

Coverage:
- Overlap: {N} controls ({percent}%)
- Unique to {F1}: {N} controls
- Unique to {F2}: {N} controls
- Conflicts: {N}

Control Mapping:
| {F1} Control | {F2} Control | Status |
|-------------|-------------|--------|
| {control}   | {control}   | MAPPED |
| {control}   | --          | GAP    |

Migration Effort (from {F1} to {F1}+{F2}):
- Already covered: {N} controls
- Additional work: {N} controls ({effort} total effort)

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Mapping from NIST | `[nist-map]` for detailed NIST analysis |
| ISO crosswalk needed | `[iso-crosswalk]` for ISO-specific mapping |
| Building control catalog | `[control-catalog]` to document all controls |
