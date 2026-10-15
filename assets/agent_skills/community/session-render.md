---
name: session-render
description: Render session research artifacts as a beautiful self-contained HTML dashboard and open in browser
version: 1.0.0
execution-mode: side_effecting
argument-hint: "optional focus area (e.g. \"competitive\", \"positioning\", \"mythos\")"
category: dev-tools
status: candidate
---
# Session Render

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=session-render] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Generate a beautiful self-contained HTML dashboard from session research artifacts and open it in the browser. Use when the user says "show me everything in a browser", "make it pretty", "render the research", or "session render".

## What to Collect

1. **Evidence docs** — most recent 5 from `hummbl_governance/docs/research/evidence/` (by filename date)
2. **Positioning brief** — `hummbl_governance/docs/reference/HUMMBL_POSITIONING_BRIEF_APR2026.md` if it exists
3. **Competitive landscape** — `hummbl_governance/docs/research/competitor_landscape_*.md` (most recent)
4. **Today's date** — for filename and header

If `$ARGUMENTS` specifies a focus area, prioritize docs matching that keyword.

## HTML Structure

Dark theme (`#0a0a0f` background), card-based layout, color-coded by section:
- Purple stripe: positioning / pitch / white spaces
- Red stripe: urgency / risk / mythos
- Green stripe: ICP / pricing / opportunities
- Blue stripe: stats / competitive / landscape
- Yellow stripe: dates / model landscape / regulatory

Key sections to include (when data is available):
1. **Header** — session date, branch, badges (urgency status, ledger count)
2. **Core Positioning** — one-line pitch + dual urgency stack
3. **Opening Stats** — CSA stats as large-number grid
4. **Three White Spaces** — as three-column card grid
5. **Competitive Landscape** — full table with threat tiers
6. **Counter-Narratives** — ready-to-use talking points
7. **ICP + Pricing** — side by side
8. **Model Landscape** — table of frontier models
9. **Key Dates** — forward-looking calendar
10. **Pitch Deck Updates Required** — action checklist
11. **Footer** — ledger count, evidence doc count, pending actions

## Generation

```python
import os, datetime

date_str = datetime.date.today().isoformat()
out_dir = "hummbl_governance/_internal/session-render"
os.makedirs(out_dir, exist_ok=True)
out_path = f"{out_dir}/{date_str}.html"

# Build HTML string with all available content
html = build_html(collected_content)

with open(out_path, "w") as f:
    f.write(html)
```

Open with: `open <out_path>`

## Output

```
Session Render | {date} | {focus or "full"}
══════════════════════════════════════════

Generated: {out_path}
Sections: {list of sections rendered}
Evidence docs included: {N}
Opened in browser: YES

Next: Review, then consider [send-email] dan to share the brief
```

## Skill Chains

### Mandatory

None — file generation only. No pre-chain required; this skill reads existing research artifacts and renders HTML.

### Advisory

- `[session-render]` → `[send-email]` — email the briefing HTML as an attachment or summary
- `[session-render]` → `[commit]` — commit the generated HTML to `_internal/session-render/`
- `[session-render]` → `[social-post]` — if the research warrants a LinkedIn post

## Authority

- **T1 (TRUSTED)**: Full run — generate and open HTML dashboard
- **T2 (Active/High)**: Full run — generate and open HTML dashboard
- **T3 (Medium)**: Full run — generate and open HTML dashboard
- **T4 (Probationary)**: File generation only — may render HTML but must not open browser or commit without operator approval
- **Operator**: Override any restriction
