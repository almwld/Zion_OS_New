---
name: testimonial
description: Collect, format, and organize client testimonials for marketing materials
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action add|list|format] [--client NAME]"
category: sales-marketing
status: candidate
---
# Testimonial

Collect, store, format, and organize client testimonials for use in marketing materials, proposals, and case studies. Maintains a testimonial library with metadata for easy retrieval.

## When to Use
- A client provides positive feedback you want to capture formally
- You need to pull testimonials for a proposal or pitch deck
- You want to format raw feedback into polished marketing quotes
- You need to organize testimonials by industry, service, or outcome

## Execution
1. Parse `$ARGUMENTS` for action (add/list/format) and optional client name
2. If `add`: collect testimonial text, client name, title, company, date, and tags (industry, service)
3. If `list`: display all stored testimonials with filters by client, tag, or recency
4. If `format`: transform raw feedback into polished testimonial formats:
   - Pull quote (1-2 sentences, bold key phrase)
   - Card format (quote + attribution + logo placeholder)
   - Case study excerpt (context + quote + result)
5. Store in a structured format for cross-session retrieval
6. Suggest placement opportunities (website, proposal, deck)

## Output Format
```
Testimonial | <action>

## Testimonial
> "<polished quote>"
> -- <Name>, <Title>, <Company>

## Metadata
- Date: <date>
- Tags: <industry>, <service>
- Source: <email|call|survey|unsolicited>
- Permission: <granted|pending|not_requested>

## Formatted Versions
### Pull Quote
**"<key phrase>"** -- <attribution>

### Card
<full formatted card>

### Case Study Excerpt
<contextual version>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| From a case study | `[case-study]` to build the full story |
| For a pitch deck | `[pitch]` to integrate into materials |
| For a proposal | `[proposal-write]` to include social proof |
