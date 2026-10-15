---
name: one-pager
description: One-page brief synthesized from scratch. Headline, problem, solution, why now, proof, ask. Exactly one page. For prospects, partners, investors, or concept clarity.
version: 1.0.0
execution-mode: advisory
argument-hint: "<topic: hummbl | bki | arcana | [company name] | [concept]>"
category: sales-marketing
status: tested
providers:
  required: [bash, python]
---
# [one-pager]

> One page forces the decision you're avoiding: what actually matters.

Different from `[exec-summary]` (summarizes an existing document) — this synthesizes from scratch and fits exactly one page. When you can't explain it in one page, you don't understand it well enough yet.

## When to Use
- Prospect asks "can you send me something?" after a call
- Partner intro needs a leave-behind
- Investor wants a quick overview before a meeting
- Internal: forcing function for clarity before building

## Format (one page, printable)

**Section weights:**
- Headline: 1 line
- Problem: 2-3 lines
- Solution: 3-4 lines
- Why now: 1-2 lines
- Proof: 3 bullets (no more)
- Ask: 1 line

## Execution

### 1. Identify the audience
The one-pager changes based on who's reading it:
- **Legal/Risk buyer**: lead with compliance risk and audit trail
- **IT/CTO buyer**: lead with integration, standards (NIST, ISO), control plane
- **CEO/Board**: lead with competitive advantage and liability reduction
- **Investor**: lead with market size, timing, traction
- **Partner**: lead with shared customer problem and complementary capabilities

### 2. Build from context

```bash
# Load relevant memory and context (resolve runtime memory dir)
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
cat "$RUNTIME_MEM/project_hummbl_strategy_apr6.md" 2>/dev/null
cat "$RUNTIME_MEM/project_bki_framework.md" 2>/dev/null
cat ~/.agents/_internal/outreach/wave1-drafts.md 2>/dev/null | head -30
```

### 3. Apply the one-page template

```
[HEADLINE]
[Company/Product] [verb] [outcome] for [audience].

THE PROBLEM
[2-3 lines. Be specific. Name the pain, not the category.]

THE SOLUTION
[3-4 lines. What it does, not how it works. Customer language.]

WHY NOW
[1-2 lines. What changed that makes this the right moment?]

PROOF
• [Specific evidence — early customer, pilot result, adoption signal]
• [Framework/standard alignment — NIST AI RMF, EU AI Act, etc.]
• [Founder/team credibility or unique insight]

THE ASK / NEXT STEP
[1 line. Specific and low-friction.]
[Contact: reuben@hummbl.io | cal.com/hummbl/30min]
```

## Standard One-Pagers to Have Ready

| Version | Audience | Headline focus |
|---------|----------|---------------|
| `hummbl` | General | AI governance infrastructure |
| `hummbl-legal` | Legal/Risk | Liability reduction and audit trail |
| `hummbl-it` | IT/CTO | NIST-aligned AI control plane |
| `bki` | Academic/L&D | Belonging as knowledge infrastructure |
| `hummbl-investor` | Investors | Market timing and traction |

## Output Format

```
One-Pager | <topic> | <audience>
══════════════════════════════════

[HEADLINE]

THE PROBLEM
[2-3 lines]

THE SOLUTION
[3-4 lines]

WHY NOW
[1-2 lines]

PROOF
• [evidence 1]
• [evidence 2]
• [evidence 3]

NEXT STEP
[ask] | reuben@hummbl.io | cal.com/hummbl/30min

---
Word count: <N> (target: <200 words)
Fits one page: <yes/no>
```

## Chain
- After a `[coffee-chat]` where they asked for materials → this
- After `[press-release]` → convert to one-pager for external use
- One-pager for investor → feeds into `[investor-update]`
- Prospect version → attach to `[send-email]` follow-up
