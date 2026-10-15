---
name: demo-script
description: Scripted product demo with timing, talking points, fallback plans for failures
version: 0.1.0
execution-mode: advisory
argument-hint: "<product> [--audience AUDIENCE] [--duration MINUTES]"
category: hummbl-research
status: candidate
---
# Demo Script

Create a scripted product demonstration with precise timing, talking points per step, and fallback plans for when things go wrong. Designed for live demos where reliability matters.

## When to Use
- You are preparing a live product demo for investors, clients, or conferences
- You need a step-by-step script with exact commands and expected outputs
- You want fallback plans for common demo failures (network, auth, data)
- You need to rehearse a demo with timing checkpoints

## Execution
1. Parse `$ARGUMENTS` for product/feature name, audience type, and duration (default 10 min)
2. Identify the key features to demonstrate based on audience
3. Script each step: action, expected result, talking point, timing
4. Create "Plan B" fallbacks for each step (screenshots, pre-recorded video, cached data)
5. Add setup checklist (pre-demo verification steps)
6. Add reset script (how to return to clean state for re-demo)
7. Present the complete demo package

## Output Format
```
Demo Script | <product> (<duration> min)

## Setup Checklist (run 15 min before)
- [ ] <verification step>
- [ ] <verification step>

## Script
| Time | Step | Action | Say | Fallback |
|------|------|--------|-----|----------|
| 0:00 | Intro | Open app | "Let me show you..." | N/A |
| 0:30 | Feature 1 | <action> | <talking point> | <fallback> |
| ... | ... | ... | ... | ... |

## Reset Script
<commands to reset demo state>

## Risk Register
| Risk | Probability | Mitigation |
|------|-------------|------------|
| Network down | Medium | Use cached responses |
| ... | ... | ... |

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Demo is for investors | `[pitch]` to build the narrative |
| Need meeting context | `[meeting-prep]` for audience research |
