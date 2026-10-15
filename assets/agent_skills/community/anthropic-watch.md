---
provider-specific: true
name: anthropic-watch
description: Track bleeding-edge Anthropic announcements -- model releases, API changes, Claude Code updates, partner programs, safety research, policy positions.
version: 0.1.1
execution-mode: advisory
argument-hint: "[--depth quick|full] [--focus models|api|code|safety|policy|all]"
category: fleet-ops
status: candidate
---
# Anthropic Watch

Stay current on Anthropic announcements, releases, and ecosystem changes. Designed to catch things within hours/days of publication, not weeks.

## HUMMBL Market Intel Frame

Default reporting structure for material findings:

1. `position`
   Anthropic's explicit stance, doctrine, policy claim, or strategic framing.
2. `action`
   The concrete launch, restriction, rollout, partnership, publication, or enforcement move.
3. `reaction`
   The measurable market, customer, policy, competitor, or public response.
4. `routing_implication`
   What HUMMBL should do with the signal: monitor, adopt, avoid, escalate, or convert into another artifact.

Use this frame by default for:

- safety and policy announcements
- cybersecurity launches
- Claude model releases
- Claude Code changes with ecosystem impact
- partner program or enterprise trust signals

Do not stop at "what happened." Convert the finding into operator-usable routing.

## When to Use
- Morning routine (pair with `[daily-research]`)
- Before pitching Anthropic partnership or updating partner app
- Before making architecture decisions involving Claude models or API
- When user asks "what's new from Anthropic?"
- Weekly cadence minimum during active partner engagement

## Default Output Shape

For each material item, prefer this compact schema:

```yaml
vendor:
date:
position:
action:
reaction:
routing_implication:
confidence:
sources:
```

If reaction is not yet measurable, say so explicitly instead of inferring market impact.

## Sources (ranked by authority)

| Priority | Source | What to Look For |
|----------|--------|-----------------|
| P1 | `anthropic.com/news` | Official announcements, model launches |
| P1 | `docs.anthropic.com/en/docs/about-claude/models` | Model cards, deprecations, context windows |
| P1 | `docs.anthropic.com/en/docs/changelog` | API changelog (breaking changes, new features) |
| P1 | `github.com/anthropics/claude-code/releases` | Claude Code releases, new tools, hooks |
| P2 | `anthropic.com/research` | Safety research, alignment papers, RSP updates |
| P2 | `anthropic.com/engineering` | Engineering blog posts, infrastructure |
| P2 | `github.com/anthropics/anthropic-cookbook` | New patterns, SDK examples |
| P2 | `github.com/anthropics/courses` | New courses, updated tutorials |
| P3 | `x.com/AnthropicAI` | Teasers, launch threads, community signals |
| P3 | `x.com/alexalbert__` | Claude Code lead -- feature previews, roadmap hints |
| P3 | `x.com/daboross` | Claude Code eng -- implementation details |
| P3 | Hacker News (`site:news.ycombinator.com anthropic`) | Community reaction, adoption signals |
| P4 | `status.anthropic.com` | Outages, rate limit changes, capacity |

## Focus Areas

| Focus | Covers | Why It Matters |
|-------|--------|---------------|
| **models** | New models, deprecations, pricing, benchmarks | Architecture decisions, cost planning |
| **api** | API changes, new endpoints, SDK updates, tool use | Integration code, breaking changes |
| **code** | Claude Code CLI, hooks, MCP, skills, permissions | Our daily tooling, skill compatibility |
| **safety** | RSP, alignment research, red teaming, evals | governance positioning, credibility |
| **policy** | Government engagement, partner program, enterprise | Partner app status, market timing |
| **all** | Everything above | Full sweep |

## Execution

### quick (default -- 3 minutes)

Headline scan across P1 sources only.

1. **Fetch official channels**:
   ```
   WebSearch "site:anthropic.com/news 2026"
   WebSearch "Anthropic announcement" (last 7 days)
   WebSearch "Claude Code release" (last 7 days)
   ```

2. **Check API changelog**:
   ```
   WebFetch "https://docs.anthropic.com/en/docs/changelog"
   Scan for entries newer than last check
   ```

3. **Check Claude Code releases**:
   ```
   WebSearch "github.com/anthropics/claude-code releases"
   Compare latest version against known version
   ```

4. **Output**: Findings table (see Output Format below)

### full (10-15 minutes)

Deep sweep across all source priorities.

1. **All quick steps** above

2. **Research blog + papers**:
   ```
   WebSearch "site:anthropic.com/research 2026"
   WebSearch "site:anthropic.com/engineering 2026"
   WebSearch "Anthropic paper arxiv 2026"
   ```

3. **Social signals**:
   ```
   WebSearch "from:AnthropicAI" (last 7 days)
   WebSearch "site:news.ycombinator.com anthropic" (last 7 days)
   ```

4. **Ecosystem + community**:
   ```
   WebSearch "anthropic partner program 2026"
   WebSearch "anthropic enterprise 2026"
   WebSearch "Claude MCP server new"
   ```

5. **Competitive context** (brief):
   ```
   WebSearch "OpenAI announcement" (last 7 days) -- for contrast
   WebSearch "Google AI announcement" (last 7 days) -- for contrast
   ```

6. **Output**: Full findings table + analysis + implications

## Output Format

```
Anthropic Watch | {date} | {focus} | {depth}
============================================

## New Findings

| # | Date | Category | Finding | Source | Impact |
|---|------|----------|---------|--------|--------|
| 1 | ... | model | ... | P1: anthropic.com/news | HIGH -- affects our ... |

## Breaking Changes / Action Required
(Only if applicable)
- [ ] ACTION: ...

## Model Status (if focus=models or all)
| Model | Status | Context | Price (in/out per MTok) |
|-------|--------|---------|------------------------|
| ... | ... | ... | ... |

## Claude Code Status (if focus=code or all)
- Installed version: `claude --version`
- Latest release: ...
- Notable changes: ...

## Implications for Your Organization
- Partner app: ...
- Architecture: ...
- Positioning: ...

## Next Check
Suggested: {date + cadence}
```

For policy-sensitive or market-moving items, append a structured block using the HUMMBL frame:

```yaml
vendor: anthropic
date:
position:
action:
reaction:
routing_implication:
confidence:
sources:
```

## Cadence Recommendations

| Situation | Frequency | Depth |
|-----------|-----------|-------|
| Normal operations | Weekly | quick |
| Active partner engagement | Every 2 days | full |
| Model launch window | Daily | full |
| Pre-pitch or pre-meeting | Day-of | full with focus |
| Post-major-announcement | Immediate | full |

## What to Persist

After a **full** run with significant findings:
- Update memory if a model deprecation or API change affects our code
- Post to bus if a finding is actionable for other agents
- Suggest `[decision-log]` if a finding changes our architecture
- Flag to user if partner program status changes

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| New model announced | `[competitive-intel]`, update `AGENTS.md`, `.agents/ROSTER.md`, or model-tier references as applicable |
| API breaking change | `[bulk-edit]` to update affected code |
| Claude Code update | `[skill-test]` to verify skill compatibility |
| Safety paper published | `[daily-research] --ingest` to add to knowledge base |
| Partner program news | `[send-email]` to brief the team lead |
