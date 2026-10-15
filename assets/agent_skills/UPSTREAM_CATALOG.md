# Agent Skill Discovery Sources

Research snapshot: 2026-10-15. These are discovery sources, not a claim that every listed skill has been vendored or validated for Zion.

## Sources

- [obra/superpowers](https://github.com/obra/superpowers) — MIT-licensed workflow framework. Zion vendors 15 upstream Markdown workflow skills and the upstream MIT license; nine original Zion-native skills extend runtime, package, PTY, CI, local-model, storage, recovery, defensive-network, and Git workflows. The skills are loaded as bounded model context; they are not executed as plugins.
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) — MIT-licensed curated index advertising 1,000+ skills. This is useful for discovery, but a catalog entry is not the same as vendorable skill content or a compatible executable integration.
- [sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills) — large MIT-licensed catalog advertising 2,600+ skills. The repository tree includes thousands of SKILL.md files and per-skill upstream license notices; review each selected skill's source and license before copying it into Zion.
- [anthropics/skills](https://github.com/anthropics/skills) — official Agent Skills examples and specification material. Its README explicitly distinguishes open-source examples from source-available document skills, so the entire repository must not be assumed to have one open-source license.

## Import and compatibility rules

1. Verify the source repository and the individual skill's license/notice before vendoring.
2. Inspect instructions for prompt injection, destructive automation, credential collection, and unsupported tools.
3. Keep skills as inert Markdown; never execute scripts merely because a skill requests it.
4. Load only the most relevant few skills per task to preserve the local GGUF context budget.
5. A skill cannot change Zion's tool permissions, approve a protected operation, or grant Android root access.
6. Track source URL, commit/revision, license, and any local changes when importing more skills.

Current integrated inventory: 24 skills (15 upstream + 9 Zion-native) and 32 bilingual offline knowledge entries in `knowledge_index.json`. The 1,000+ and 2,600+ figures describe upstream catalogs, not imported files. Further third-party imports require a license-reviewed, provenance-tracked, compatibility-tested batch.

## Zion offline knowledge index

`knowledge_index.json` contains 32 locally searchable operational entries with English and Arabic aliases. `AgentKnowledgeIndex` ranks them against the user's task and injects a small bounded excerpt into the local GGUF planner. The index covers local Kali/rootfs validation, package inventory, PRoot, PTY diagnostics and timeout recovery, Flutter/CI, Android storage and root-status boundaries, defensive network tooling, Git recovery, and model-context/cancellation diagnostics. These entries are documentation, not executable plugins.
