---
name: user-journey
description: Map what users see, think, feel, and do at each stage of interacting with a product. Maps to P5.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"PERSONA\" (e.g., \"founder setting up Morning Briefing\", \"new GaaS customer\")"
category: data-science
status: candidate
---
# User Journey (P5: Empathy Mapping)

Systematically capture the user's experience at each touchpoint to identify friction, delight, and opportunity.

## When to Use
- Designing onboarding flows
- Identifying why users drop off
- Planning a new feature from the user's perspective
- Preparing for user interviews
- GaaS customer journey mapping

## Execution

### 1. Define the persona
```
Name: <archetype name>
Role: <job title / situation>
Goal: <what they're trying to accomplish>
Context: <technical skill, time pressure, emotional state>
```

### 2. Map the journey stages

| Stage | What they DO | What they THINK | What they FEEL | Touchpoint |
|-------|-------------|-----------------|----------------|------------|
| **Discover** | Find the product | "Does this solve my problem?" | Curious, skeptical | Website, GitHub, HN |
| **Evaluate** | Try it out | "Is this worth my time?" | Hopeful, impatient | README, demo, free tier |
| **Onboard** | Set up and configure | "This better work..." | Anxious, determined | Docs, CLI, first run |
| **First Value** | Get first useful result | "Oh, this actually works" | Relief, excitement | First briefing, first agent |
| **Habit** | Use regularly | "Part of my workflow now" | Confident, dependent | Daily briefing, bus |
| **Expand** | Add agents, skills, integrations | "What else can this do?" | Ambitious, creative | Skill registry, MCP |
| **Advocate** | Recommend to others | "You need to try this" | Proud, evangelical | Twitter, HN, word of mouth |

### 3. Identify friction points
For each stage, what makes the user:
- **Stop**: Abandon entirely (critical friction)
- **Pause**: Hesitate but continue (medium friction)
- **Grumble**: Complete but annoyed (low friction)

### 4. Identify delight points
What exceeds expectations? What makes them say "wow"?

### 5. Prioritize interventions
| Friction | Stage | Impact | Fix Effort | Priority |
|----------|-------|--------|-----------|----------|
| <description> | <stage> | H/M/L | H/M/L | P0/P1/P2 |

## Output Format
```
User Journey | <persona>
════════════════════════════

## Persona
<name, role, goal, context>

## Journey Map
<stage table with DO/THINK/FEEL/TOUCHPOINT>

## Friction Points (by severity)
- [STOP] <stage>: <what blocks them>
- [PAUSE] <stage>: <what slows them>
- [GRUMBLE] <stage>: <what annoys them>

## Delight Points
- <stage>: <what exceeds expectations>

## Recommendations
1. <highest-impact intervention>
2. <second>
3. <third>
```

## Base120 Context
- Primary: **P5** (Empathy Mapping)
- Related: **P2** (Stakeholder Mapping), **P7** (Perspective Switching), **SY13** (Incentive Architecture)
