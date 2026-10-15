---
name: user-discovery
description: >
  Discover the end-users of the systems and products the agent builds or
  serves — who they are, what they need, their pain points, behavior, and
  values. Composes icp-profile, user-journey, discovery-call, ethnography-plan,
  grounded-theory, churn-analysis, and win-loss into a unified user profile.
  Invoke when an agent says "who are the users", "user discovery", "user
  research", "who is this for", "what do users need", "user persona", or
  before starting product work that requires understanding the end-user.
version: 0.1.0
execution-mode: advisory
argument-hint: "[optional: --market | --persona | --journey | --feedback | --full]"
category: cognitive
status: candidate
---

# User-Discovery

Discover the end-users of the systems and products the agent builds or serves.
This is the outward-facing complement to `[self-discovery]`: self-discovery
answers "what am I?" while user-discovery answers "who is this for?"

## Why User-Discovery Matters

Agents that don't know their users make avoidable mistakes:

- An agent builds a feature for a buyer persona when the end-user is different
- An agent writes technical documentation for a non-technical audience
- An agent optimizes for acquisition when retention is the real problem
- An agent assumes the user's workflow without observing it
- An agent ships a feature that no one asked for because they didn't validate
- An agent treats all users as the same when segments have different needs

User-discovery is not market research — it is product calibration. Know the
user before you build.

## The Discovery Procedure

Follow these 5 phases in order. Each phase has probe commands (run existing
skills) and reflection questions (synthesize findings).

### Phase 1: Market and Landscape Discovery

**What to discover:** Who exists in this space, who else serves these users,
and where are the unmet needs.

**Probe commands:**

```
[competitive-intel] "<market or category>"
[market-gap-finder] "<market or category>"
[industry-watch]  (if AI-adjacent)
```

**Reflection questions:**
- Who else serves these users? What do they offer? Where do they fall short?
- What unmet needs and whitespace opportunities exist?
- What market trends are shaping user expectations?
- Is there a gap between what's available and what users need?

**Record:** `market_landscape: { competitors: [...], gaps: [...], trends: [...], whitespace: [...] }`

### Phase 2: User Profiling

**What to discover:** Who are the users — their roles, goals, fears, pain
points, behaviors, and decision criteria.

**Probe commands:**

```
[icp-profile] "<segment or vertical>"  (reframe "buyer" → "user")
[user-journey] "<persona>" --stage all  (if persona is known)
```

If personas are not yet defined, generate them from the ICP output:

**Reflection questions:**
- Who is the primary user? (distinct from the buyer/economic buyer)
- Who is the champion user? (the person who advocates internally)
- What are the user's goals? Fears? Pain points?
- What is the user's role, seniority, technical level?
- What triggers the user to seek this product/service?
- What would disqualify a user from being a good fit?

**Record:** `user_profile: { primary_persona: {...}, champion_persona: {...}, goals: [...], fears: [...], pain_points: [...], triggers: [...], disqualifiers: [...] }`

### Phase 3: Primary Research

**What to discover:** Validate and deepen understanding through direct user
contact.

**Probe commands:**

```
[discovery-call] "<prospect or user>"  (adapt from sales to product discovery)
[ethnography-plan] "<field site or user context>"  (for deep immersion)
[field-research]  (if ethnography plan is approved)
[usability-test] "<task or flow>"  (for existing products)
```

**Reflection questions:**
- What do users actually do (vs what they say they do)?
- Where do users struggle? Where do they find delight?
- What workflows does the user follow that the product doesn't support?
- What language do users use to describe their problems? (capture verbatim
  quotes)
- What would make the user's life easier?

**Record:** `research_findings: { observations: [...], interviews: [...], usability_issues: [...], verbatim_quotes: [...], workflow_gaps: [...] }`

### Phase 4: Experience and Need Mapping

**What to discover:** Structure findings into journey maps, value
propositions, and need statements.

**Probe commands:**

```
[user-journey] "<persona>" --format full
[value-prop] "<segment>" "<product>"
[gap-analysis]  (adapt: gap between user needs and current product)
```

**Reflection questions:**
- What does the user's journey look like from discover to advocate?
- Where are the friction points? Where are the delight points?
- What value proposition resonates with this user segment?
- What gaps exist between what users need and what the product delivers?
- What features would address the biggest gaps?

**Record:** `experience_map: { journey_stages: [...], friction_points: [...], delight_points: [...], value_proposition: ..., need_gaps: [...] }`

### Phase 5: Relationship and Feedback Loops

**What to discover:** Maintain user relationships and capture longitudinal
discovery signals.

**Probe commands:**

```
[crm] view  (existing user contacts)
[engagement-tracker]  (active engagement health)
[churn-analysis]  (why users leave)
[win-loss]  (what users value vs what drives them away)
```

**Reflection questions:**
- What do users who stay have in common? What do users who leave have in
  common?
- What engagement health signals are present?
- What churn signals have been detected?
- What patterns appear in won vs lost deals?
- What testimonials and case studies provide user voice evidence?

**Record:** `feedback_loops: { retention_patterns: [...], churn_signals: [...], win_patterns: [...], loss_patterns: [...], testimonials: [...] }`

## Producing the User Profile

After completing all 5 phases, synthesize into a single User Profile artifact:

### User Profile (human-readable)

```markdown
# User Profile

## Market Landscape
- Competitors: [list]
- Unmet needs: [list]
- Market trends: [list]

## Primary User Persona
- Role: [role]
- Goals: [list]
- Fears: [list]
- Pain points: [list]
- Technical level: [level]
- Triggers: [list]

## User Journey
- Discover: [what happens]
- Evaluate: [what happens]
- Onboard: [what happens]
- First value: [what happens]
- Habit: [what happens]
- Expand: [what happens]
- Advocate: [what happens]

## Friction Points
- [list with severity]

## Delight Points
- [list]

## Value Proposition
- [statement]

## Need Gaps
- [list with priority]

## Feedback Signals
- Retention patterns: [description]
- Churn signals: [description]
- Win/loss patterns: [description]

## What This Agent Should Know
- [3-5 actionable insights for serving these users]
```

### User Profile (bus summary)

```
USER_PROFILE: segment=[segment] primary_persona=[role] pain_points=[N] friction=[N] delight=[N] value_prop=[statement] churn_risk=[low|medium|high] intel_type=TOPOINT
```

### User Profile (ledger persistence)

```
[ledger] post --type user-profile --tags user,discovery,persona,journey --content "<profile JSON>"
```

## When to Re-Run User-Discovery

- **Before new product work**: Establish who the product is for
- **Quarterly**: Refresh market landscape and feedback loops
- **After churn event**: Re-discover why users are leaving
- **After win/loss pattern shift**: When win/loss ratios change significantly
- **Before feature design**: Validate that the feature serves a real user need
- **When asked**: "Who are the users?" / "What do users need?"

## Argument Modes

- `[user-discovery]` — Full 5-phase procedure (default)
- `[user-discovery] --market` — Phase 1 only (market landscape)
- `[user-discovery] --persona` — Phase 2 only (user profiling)
- `[user-discovery] --journey` — Phase 4 only (experience mapping, requires
  existing persona)
- `[user-discovery] --feedback` — Phase 5 only (feedback loop analysis)
- `[user-discovery] --full` — All 5 phases (same as default)

## Composition Chain

- `[self-discovery]` → `[user-discovery]` → `[empathy-map]` — Full
  calibration: know yourself, know your users, know what they experience
- `[user-discovery]` → `[prd-write]` — User profile feeds product requirements
- `[user-discovery]` → `[value-prop]` — User profile informs positioning
- `[user-discovery]` → `[outreach-strategy]` — User profile shapes outreach

## Anti-Patterns

- **Don't confuse buyer and user**: The economic buyer is not always the
  end-user. Profile both separately.
- **Don't skip primary research**: ICP profiles are hypotheses. Validate with
  real user contact.
- **Don't fabricate personas**: If you don't have research data, say so. Don't
  invent user quotes or behaviors.
- **Don't skip churn analysis**: Why users leave is as important as who they
  are.
- **Don't make it long**: The profile should be concise and actionable.

## Known Limitations

- `[market-gap-finder]` and `[prd-write]` are currently stubs — Phase 1 and
  Phase 4 may have limited output until these are developed
- `[hummbl-sales-pipeline]` and `[hummbl-market-intelligence]` are pointer
  stubs requiring access to the hummbl-skills repo
- No dedicated persona-generation skill exists — personas are derived from
  `[icp-profile]` output with manual reframing
- No survey/quantitative research skill exists — all research is qualitative
- No product analytics/instrumentation skill exists — passive behavior
  observation is not covered

## After This Skill Runs

- `[empathy-map]` — Deepen user understanding with empathy mapping
- `[prd-write]` — Translate user needs into product requirements
- `[value-prop]` — Craft value propositions from user pain points
- `[outreach-strategy]` — Design outreach based on user profile
