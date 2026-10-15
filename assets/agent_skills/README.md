# Zion Super Agent Skills

This directory contains concise, Android-friendly skill playbooks written for Zion's local-model planner. The runtime ranks skills by task relevance and injects only a small context window into each plan request.

## Built-in playbooks

- `systematic-debugging.md` — investigate evidence and isolate root causes before editing.
- `test-driven-development.md` — specify a behavior, test it, implement, and re-run regressions.
- `verification-before-completion.md` — require fresh evidence before claiming success.
- `writing-plans.md` — break work into verifiable, dependency-aware steps.
- `brainstorming.md` — compare feasible approaches and clarify constraints before large changes.
- `executing-plans.md` — execute incrementally, observe real outputs, and recover from failures.

## Skill format and compatibility

Skills use plain Markdown with optional YAML frontmatter (`name`, `description`). The loader is offline-first and never executes scripts contained in skill documents. Skill text is guidance to the model, not an authorization grant: tool policy and the Android runtime remain authoritative.

## Upstream inspiration and attribution

The workflow ideas are informed by the MIT-licensed [obra/superpowers](https://github.com/obra/superpowers) project. These Zion playbooks are concise original adaptations rather than verbatim copies. See the upstream repository for its current license and full skill texts.

## Adding skills

Add a Markdown file, register it in `AgentSkillLibrary`, and add a focused test for its relevance and loading behavior. Keep each skill task-oriented, measurable, and suitable for local-model context budgets.
