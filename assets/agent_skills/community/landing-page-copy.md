---
name: landing-page-copy
description: Write landing page copy — hero, problem/solution, benefits, social proof, FAQ, and CTA sections. Conversion-optimized, above-fold tested. Saves to _internal/marketing/. Powered by copywriter agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"PRODUCT\" \"ICP\" \"PRIMARY_CTA\" [--tone challenger|educational|founder] [--length short|full]"
category: sales-marketing
status: tested
providers:
  required: [bash, python]
---
# Landing Page Copy

Generate complete landing page copy for a SaaS product, service, or campaign page.

## When to Use

- Launching or revamping the main product page
- Building a campaign landing page for outbound email
- Creating a specific ICP-targeted page (e.g., healthcare-specific, fintech-specific)
- A/B testing new messaging

## Required Inputs

| Field | Example |
|-------|---------|
| Product | HUMMBL AI Governance Platform |
| ICP | Enterprise AI compliance officers, CTOs at regulated companies |
| Primary pain point | "Don't know if their AI is compliant — and can't prove it if asked" |
| Primary CTA | Book a 30-minute governance assessment |
| Proof points | Covers NIST AI RMF, ISO 42001, EU AI Act, OWASP LLM Top 10 |
| Tone | Challenger (reframe the problem) |

## Landing Page Sections

### 1. Above the Fold (Most Critical)
```
HEADLINE: [What it does + who it's for, in 8 words or less]
SUBHEAD: [The key mechanism or proof in 15 words or less]
CTA: [Button text — specific, action-oriented, low-friction]
TRUST LINE: [Social proof or credibility signal]
```

### 2. Problem Section
Frame the pain the ICP recognizes. Make them feel seen.

### 3. Solution Section
How the product solves it. Focus on mechanism, not features.

### 4. Benefits (Not Features)
3-4 bullets. Each one answers "so what?" for the ICP.

### 5. Social Proof
- Quotes (or placeholder quotes with [ROLE, COMPANY TYPE])
- Logos if available
- Stats if available (label as [ESTIMATE] if not confirmed)

### 6. How It Works (Optional)
3-step process. Reduces friction by making it concrete.

### 7. FAQ
3-5 questions that handle the most common objections.

### 8. Bottom CTA
Restate the offer. Remove last objection. One button.

## Above-Fold Test

Before finalizing, the agent evaluates the above-fold against:
- **3-second test**: Can a stranger tell what this is and who it's for in 3 seconds?
- **Clarity test**: Is the headline specific or generic? (generic = fail)
- **Action test**: Does the CTA tell you exactly what happens when you click?

## Human Cost Equivalent

- Short landing page (above-fold + 3 sections): $500-1,200
- Full landing page (8 sections): $1,200-2,400
- Conversion-optimized with A/B variants: $2,400-4,000

## Skill Chains

- `[landing-page-copy]` → `[frontend]` (implement the copy as a webpage)
- `[landing-page-copy]` → `[seo-check]` (optimize for search)
- `[landing-page-copy]` → `[content-review]` (check before publishing)
- `[landing-page-copy]` → `[email-sequence]` (cold email that drives to the landing page)
- A/B test → `[experiment]` (track conversion rate by variant)
