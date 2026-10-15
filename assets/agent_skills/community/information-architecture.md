---
name: information-architecture
description: Structure navigation, taxonomy, page hierarchy, content grouping, labels, and findability. Use for sitemap, nav, dashboard organization, documentation structure, settings pages, or confusing information layouts.
version: 0.1.0
execution-mode: advisory
argument-hint: <site-app-docs-or-content-set>
category: dev-tools
status: candidate
---
# Information Architecture

## Purpose

Answer: "Can users find, understand, and navigate the information?"

## Workflow

1. Identify users, top tasks, and decision points.
2. Inventory content, screens, objects, and actions.
3. Group by user mental model, not implementation structure.
4. Review labels for clarity, ambiguity, and consistency.
5. Check navigation depth, cross-links, breadcrumbs, search/filter needs.
6. Recommend taxonomy, hierarchy, naming, and migration steps.

## Output

```markdown
IA Verdict: <clear | fragmented | confusing | missing>
Primary Users: <users>
Top Tasks: <tasks>
Current Structure: <summary>
Problems: <ranked list>
Recommended Structure: <tree/list>
```

## Rules

- Prefer user task language over internal system names.
- Do not flatten everything; hierarchy should reflect decisions and frequency.
- Label uncertainty when user research is missing.
