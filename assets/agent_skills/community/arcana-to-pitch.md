---
name: arcana-to-pitch
description: Transform ARCANA multi-lens synthesis outputs into HUMMBL pitch materials. Converts philosophical research findings into email openers, one-pagers, discovery call talk tracks, and deck slides. Sources each claim from its originating ARCANA lens for credibility trail.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"AUDIENCE\" \"FORMAT\" [--source <ARCANA_SOURCE_PATH>]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# ARCANA to Pitch

Convert ARCANA multi-lens philosophical analysis into audience-specific HUMMBL pitch materials. Each output cites the source lens and finding for credibility.

## When to Use
- Turning governance research into cold outreach email openers
- Preparing a one-pager for a CISO, CAIO, or board before a discovery call
- Building a discovery call talk track from first principles
- Extracting 5 deck bullets from the ARCANA synthesis for a pitch slide
- Translating academic/philosophical findings into enterprise sales language

## Usage

```
[arcana-to-pitch] "AUDIENCE" "FORMAT" [--source path]
```

**AUDIENCE options:** `ciso`, `caio`, `board`, `investor`, `enterprise-hr`, `regulator`, `vp-engineering`

**FORMAT options:**
- `email` — cold outreach opener, 150-200 words
- `one-pager` — 750-word exec summary with problem / evidence / solution / CTA
- `talk-track` — 5-7 minute discovery call script with transitions and probing questions
- `pitch-slide` — 5 bullet points formatted for a deck slide

**Optional `--source`:** Path to an ARCANA artifact. If omitted, the skill uses the hard-coded Core Findings below.

### Examples

```
[arcana-to-pitch] "ciso" "email"
[arcana-to-pitch] "board" "one-pager"
[arcana-to-pitch] "caio" "talk-track"
[arcana-to-pitch] "investor" "pitch-slide" --source PROJECTS/arcana/research_q1_q5_synthesis.md
```

---

## Core ARCANA Findings (Hard-Coded Fallback)

These are the convergent findings from ARCANA's 7+ lens analysis of the five major AI governance frameworks (EU AI Act, NIST AI RMF, ISO 42001, OECD AI Principles, UNESCO AI Ethics Recommendation). Use these when `--source` is not provided.

### Finding 1 — The Feedback Gap (Primary Differentiator)
**Claim:** Not one of the five major AI governance frameworks contains a feedback mechanism from harm events back to framework revision.
**Source lenses:** Popper (falsifiability), Taleb (antifragility), Habermas (communicative rationality)
**Implication:** Organizations following these frameworks are flying blind — they comply, but they cannot learn. Compliance does not equal resilience.
**Pitch translation:** "Every major AI governance framework is static. When something goes wrong, there is no closed loop back to the rules. HUMMBL is that loop."

### Finding 2 — Compliance Theater vs. Behavioral Change (BKI Lens)
**Claim:** Governance mandates delivered into low-belonging organizations produce compliance theater, not behavioral change. The belonging condition must precede content delivery.
**Source lenses:** Bourdieu (habitus/field — governance as symbolic capital), Habermas (communicative rationality — legitimacy requires discourse), Walton & Cohen (+0.3 SD belonging effect on performance)
**Implication:** Documentation overhead and training programs fail not because they are poorly designed, but because the organizational substrate (belonging infrastructure) is absent.
**Pitch translation:** "Most AI governance consulting sells paperwork. We build the organizational conditions that make governance stick — starting with the belonging infrastructure that turns mandates into behavior."

### Finding 3 — The Structural Precondition Problem
**Claim:** Knowledge creation, governance adoption, and behavioral transformation all share a common structural precondition: belonging. Without it, correct frameworks are processed as threats, not knowledge.
**Source lenses:** BKI Theory (Cognitive Scaffolding proposition — low belonging activates amygdala threat response, suppresses prefrontal cortex), Bourdieu (relational validation — authority flows through networks, not logic), Edmondson (+35% complex problem-solving under psychological safety)
**Implication:** You cannot governance-train your way out of a low-trust organization. You must address the belonging condition first.
**Pitch translation:** "HUMMBL doesn't just audit your AI risk. It builds the trust infrastructure that makes your people actually change how they use AI."

---

## Pitch Templates by Format

### FORMAT: email
**Target length:** 150-200 words
**Structure:**
1. Hook (1 sentence) — name a specific pain they have right now
2. Insight (2-3 sentences) — share the ARCANA finding most relevant to their role; cite the frameworks it came from
3. Differentiation (1-2 sentences) — what HUMMBL does that no one else does
4. CTA (1 sentence) — low-friction ask (15-minute call, not a demo)

**Audience calibration:**
- `ciso` → lead with the feedback gap (Finding 1); frame as audit liability
- `caio` → lead with behavioral change (Finding 2); frame as adoption failure risk
- `board` → lead with structural precondition (Finding 3); frame as governance ROI
- `investor` → lead with all 3; frame as category creation opportunity
- `enterprise-hr` → lead with Finding 3; frame as change management failure mode

### FORMAT: one-pager
**Target length:** ~750 words
**Structure:**
```
HEADLINE: [Problem statement in their language]

THE FINDING (2 short paragraphs)
- What ARCANA found across 5 major frameworks
- Why this matters for [AUDIENCE ROLE] specifically

THE ROOT CAUSE (1 paragraph)
- BKI explanation: why governance mandates fail structurally
- Cite the lens (Bourdieu, Habermas, or Walton/Cohen as appropriate)

WHAT HUMMBL DOES DIFFERENTLY (bullet list, 4-5 items)
- The closed loop from harm events to framework revision
- Belonging infrastructure as the governance substrate
- Receipts-first transparency (not documentation overhead)
- Continuous behavioral signal vs. point-in-time audit
- Quantified trust scores, not checkbox compliance

EVIDENCE (1 paragraph)
- Reference the ARCANA analysis: 7 analytical lenses, 5 frameworks, convergent finding
- Reference BKI research: Walton/Cohen, Edmondson, Bourdieu (do NOT invent numbers — use only cited evidence)

CALL TO ACTION
- [Specific next step for audience]
```

### FORMAT: talk-track
**Target length:** 5-7 minutes spoken (roughly 700-900 words at conversational pace)
**Structure:**
```
OPENING (30 seconds)
- Thank them for the time; set a single agenda: "I want to share one finding and see if it resonates"

THE RESEARCH HOOK (60-90 seconds)
- "We ran a philosophical analysis of the five frameworks your team is probably working against..."
- Deliver Finding 1 (the feedback gap) — keep it concrete: "Not one of them has a closed loop"
- Let it land; pause

THE PROBE (60 seconds)
- "Does that match what you're seeing? When something goes wrong with an AI system — do you have a path from that incident back to the actual policy?"
- Listen for: "we're still figuring that out" / "we use [NIST/ISO] but..." / "yes and it's a mess"

THE ROOT CAUSE (60-90 seconds)
- Introduce BKI (do NOT use the academic term first)
- "The reason governance training doesn't change behavior isn't the training — it's the organizational substrate it lands in. Low-trust teams process new mandates as threats, not knowledge."
- Cite Habermas or Edmondson if they seem research-oriented; skip if they're operations-focused

THE DIFFERENTIATION (60 seconds)
- "What we build is the infrastructure that closes both loops: the feedback loop from harm to framework, and the belonging loop from mandate to behavior."
- "No one else is doing both. Most governance consulting gives you better documentation. We give you behavioral change."

THE SOFT CLOSE (30-45 seconds)
- "I'm not trying to sell you anything today — I want to know if this is even the right problem. Is the gap we found real in your org?"
- Next step: agree on what "real" looks like and whether a 45-minute working session makes sense
```

### FORMAT: pitch-slide
**Target:** 5 bullet points for a single deck slide
**Slide title suggestion:** "Why AI Governance Mandates Fail (And What Actually Works)"
**Bullets:**
```
• Zero of 5 major AI governance frameworks (EU AI Act, NIST AI RMF, ISO 42001, OECD, UNESCO) contain a feedback loop from harm events to framework revision. [Popper / Taleb lens]

• Governance training delivered into low-trust organizations produces compliance theater, not behavioral change — regardless of framework quality. [Bourdieu / BKI lens]

• The structural precondition for knowledge adoption is belonging: low-belonging teams process new mandates as threats. Belonging must precede content delivery. [Walton & Cohen / BKI]

• HUMMBL closes both loops: harm → framework revision (the governance loop) and mandate → behavior (the belonging loop). No other AI governance platform addresses both.

• Result: organizations move from point-in-time audit compliance to continuous behavioral governance — with receipts, trust scores, and a closed feedback architecture.
```

---

## Execution Instructions

When invoked, the skill should:

1. **Parse arguments:** Extract AUDIENCE and FORMAT from `$ARGUMENTS`. If missing, ask for them.
2. **Load source:** If `--source` is provided, read that file and extract top 3 differentiator claims. Otherwise, use the Core ARCANA Findings above.
3. **Select template:** Use the matching FORMAT template from Pitch Templates.
4. **Calibrate for audience:** Apply the audience-specific framing from the email section's calibration table (extends to all formats — a `ciso` talk-track leads with the feedback gap framed as audit liability, not organizational psychology).
5. **Produce output:** Generate the content. Each key claim must include an inline parenthetical citing its ARCANA source lens (e.g., `[Popper lens]`, `[BKI / Bourdieu]`).
6. **Credibility trail:** At the end of each output, include a compact `## Source Trail` section listing the 3 claims used and their originating lens.

---

## Audience Calibration Quick Reference

| Audience | Lead Finding | Frame | Language register |
|----------|-------------|-------|-------------------|
| `ciso` | Feedback gap (Finding 1) | Audit liability / regulatory exposure | Technical, risk-fluent |
| `caio` | Compliance theater (Finding 2) | Adoption failure / ROI of governance spend | Strategic, outcome-focused |
| `board` | Structural precondition (Finding 3) | Governance ROI / reputational risk | Executive, plain English |
| `investor` | All 3 | Category creation / defensible wedge | Market opportunity framing |
| `enterprise-hr` | Finding 3 | Change management failure mode | Organizational behavior language |
| `regulator` | Finding 1 | Framework gap / systemic risk | Precise, policy-adjacent |
| `vp-engineering` | Finding 1 + 2 | Operational risk / team behavior | Engineering-adjacent, concrete |

---

## Source Files (for `--source` reads)

Primary ARCANA artifacts to reference:
- `PROJECTS/arcana/research_q1_q5_synthesis.md` — Q1-Q5 synthesis with all lens outputs
- `PROJECTS/arcana/phase1-3/` — SDG map, critical analysis, HUMMBL differentiation
- `PROJECTS/arcana/bki_docs_for_claude_ai/BKI_04_PUBLISHABLE_ARTIFACTS.md` — ready pitch artifacts
- `PROJECTS/arcana/bki_docs_for_claude_ai/BKI_01_THEORY_MASTER.md` — full BKI theory

## Supadata Source Enrichment

When building a pitch, strengthen the source trail with live evidence:

```bash
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"

# Scrape competitor frameworks for gap analysis (Finding 1 — feedback gap)
python3 ~/bin/supadata.py scrape "https://www.nist.gov/itl/ai-ri[REDACTED_API_KEY]"
python3 ~/bin/supadata.py scrape "https://www.iso.org/standard/81230.html"

# Scrape regulatory guidance for compliance theater evidence (Finding 2)
python3 ~/bin/supadata.py scrape "https://digital-strategy.ec.europa.eu/en/policies/european-approach-artificial-intelligence"

# Fetch recent research on psychological safety + belonging (Finding 3)
python3 ~/bin/supadata.py scrape "https://scholar.google.com/scholar?q=psychological+safety+organizational+behavior+2025"

# Discover what competitors are publishing about AI governance
python3 ~/bin/supadata.py scrape "https://credo.ai/blog"
python3 ~/bin/supadata.py scrape "https://www.holisticai.com/blog"

# Extract conference talks or keynotes relevant to your pitch audience
python3 ~/bin/supadata.py transcript "https://youtube.com/watch?v=..." --text
```

**Use when**: The hard-coded Core Findings feel stale, or you need evidence specific to a prospect's industry/regulatory context. Source enrichment turns a templated pitch into a researched one.

---

## Output Format

```
ARCANA to Pitch | [AUDIENCE] / [FORMAT]

[Generated content here]

---
## Source Trail
1. [Claim 1] — Source: [ARCANA lens / file]
2. [Claim 2] — Source: [ARCANA lens / file]
3. [Claim 3] — Source: [ARCANA lens / file]

Next action: [Review with [content-review] before sending] OR [Load into [discovery-call] prep] OR [No further action needed]
```

---

## Skill Chains
- Before generating → `[deep-research]` (if ARCANA source files need fresh synthesis)
- After draft → `[content-review]` (check accuracy, brand alignment, claim sourcing)
- Email format → `[email-sequence]` (extend to a full sequence)
- Talk-track format → `[discovery-call]` (integrate into full pre-call prep)
- One-pager → `[exec-summary]` (condense further for C-suite)
- Pitch-slide → `[pitch]` (incorporate into a full deck)
- After finalizing → `[bki-cite-audit]` (if BKI citations need verification before publishing)
