---
name: value-prop
description: Craft and test value propositions for different audience segments with messaging hierarchy and proof points
version: 0.1.0
execution-mode: advisory
argument-hint: "<product_or_service> [--segment SEGMENT] [--format canvas|one-liner|full]"
category: fleet-ops
status: candidate
---
# Value Prop

Craft structured value propositions for a product or service, tailored to specific audience segments. Produces messaging hierarchy (headline, subhead, proof points) with competitive differentiation and testable hypotheses. Supports multiple output formats from quick one-liners to full value proposition canvases.

## When to Use
- Launching a new product or service and need positioning language
- Preparing pitch materials for a specific audience segment
- Testing whether current messaging resonates with the target market
- Differentiating from competitors in proposals or marketing copy

## Execution
1. Parse `$ARGUMENTS` for product/service name (required), segment (default: general), and format (default: `full`).
2. Research the product/service context: check repo docs, pitch materials, CLAUDE.md, and any existing positioning.
3. Identify the target segment's pain points, goals, and decision criteria.
4. Draft the value proposition components:
   - **Headline**: One sentence that captures the core value.
   - **Subheadline**: 2-3 sentences expanding on how and for whom.
   - **Key benefits**: 3 benefits mapped to segment pain points.
   - **Proof points**: Evidence, metrics, or testimonials supporting each benefit.
   - **Differentiators**: What makes this different from alternatives.
5. For `canvas` format, produce a Strategyzer-style Value Proposition Canvas.
6. For `one-liner`, produce a single sentence using the formula: "We help [segment] [achieve outcome] by [mechanism] unlike [alternative]."
7. Suggest A/B test variants for the headline.

## Output Format
```
Value Prop | product_or_service | segment | format

## One-Liner
{We help [segment] [achieve outcome] by [mechanism] unlike [alternative].}

## Messaging Hierarchy
### Headline
{Single compelling sentence}

### Subheadline
{2-3 sentence expansion}

### Key Benefits
1. {Benefit} -- {proof point}
2. {Benefit} -- {proof point}
3. {Benefit} -- {proof point}

### Differentiators
- vs {Alternative A}: {how we differ}
- vs {Alternative B}: {how we differ}

## Test Variants
- A: {headline variant A}
- B: {headline variant B}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Crafting value proposition | `[pitch]` to build full pitch materials |
| Identifying competitors | `[competitive-intel]` for deeper analysis |
| Ready to use in proposal | `[proposal-write]` to generate client proposal |
