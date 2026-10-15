---
name: press-release
description: Amazon-style working-backwards future press release. Write the headline 6 months from now, then reverse-engineer what must be true. Clarifies destination before building.
version: 1.0.0
execution-mode: advisory
argument-hint: "<initiative, product, feature, or company>"
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# [press-release]

> "Working backwards from the customer" — Amazon. Start with the press release, then build what it would take to make it real.

This is a planning tool disguised as a writing tool. The press release isn't for publishing — it's for clarity. If you can't write a compelling press release about it, you don't understand it well enough to build it.

**Use before:** starting a major feature, designing a pitch deck, or committing to a strategic direction.

## When to Use
- Before committing to build something new
- When a strategy feels right but unclear
- Pre-pitch: "what headline would make the prospect pull out their credit card?"
- When the team disagrees on what we're building and why

## Template Structure

Amazon's PR/FAQ format (adapted):

### 1. Headline
One sentence. Present tense. Future date (6 months out).
> "[Company/Product] [Verb] [Outcome] for [Customer]"
> Example: "HUMMBL Enables Equifax to Deploy 47 AI Models with Full Governance Auditability"

### 2. Subheadline
One sentence that answers "so what?"
> "[The outcome] represents [the significance]"

### 3. The Problem (2-3 sentences)
What was the world like before this existed? What pain were customers living with?

### 4. The Solution (3-4 sentences)
What does [initiative/product] actually do? Describe it as if explaining to the customer, not to an engineer.

### 5. Customer Quote
Fabricate (for planning purposes) the ideal customer quote. What would they say?
> "[Name], [Title] at [Company]: '[Quote about the value they got]'"

### 6. Founder Quote
What would you say to the press about why this matters?
> "Reuben Paul, CEO of HUMMBL: '[Quote about the mission and why this moment matters]'"

### 7. One Metric
The single number that proves it worked.
> "Organizations using [initiative] reduced AI governance overhead by X% / deployed X faster / avoided X incidents"

### 8. Call to Action
What does an interested reader do next?
> "Learn more at [hummbl.io] / request a demo at [cal.com/hummbl/30min]"

---

## Working Backwards Questions

After writing the press release, answer these to reverse-engineer the plan:

1. **What must be technically true for this headline to be possible?**
2. **What does the customer need to believe before they'd give that quote?**
3. **What's the single biggest assumption we're making that could be wrong?**
4. **What's the earliest date this headline could be real? What's blocking it?**
5. **Is there a version of this headline we could write in 6 weeks instead of 6 months?**

## Output Format

```
Press Release | <initiative> | <date written>
══════════════════════════════════════════════

FOR IMMEDIATE RELEASE
[Future date — 6 months from today]

## [HEADLINE]

## [SUBHEADLINE]

### The Problem
[2-3 sentences]

### The Solution
[3-4 sentences]

### In Their Words
"[Customer quote]"
— [Name, Title, Company]

"[Founder quote]"
— Reuben Paul, CEO, HUMMBL

### By the Numbers
[One metric]

### [Call to Action]

---
## Working Backwards
1. Technical prerequisites: [list]
2. Customer belief prerequisites: [list]
3. Key assumption: [the one that could be wrong]
4. Earliest realistic date: [date] — blocked by: [what]
5. 6-week version: [reduced scope headline]
```

## Chain
- After press release → `[scope-decompose]` to break down the "must be technically true" items
- If the headline is unclear → `[reframe]` the initiative first
- For pitch alignment → compare press release to current `[pitch]` deck
- Before board update → press release headline becomes the lede of `[investor-update]`
