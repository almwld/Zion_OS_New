# Zion Super Agent Skills and Offline Knowledge

Zion currently bundles **24 core skills plus 1,283 upstream community skills (1,307 searchable skills total)**:
- **15 upstream workflow skills** from [obra/superpowers](https://github.com/obra/superpowers), preserving the upstream MIT license and attribution.
- **9 Zion-native skills** for local runtime discovery, Linux package inventory, PTY diagnostics, Flutter/CI repair, local-model planning, Android storage inventory, evidence-driven recovery, defensive network inventory, and safe Git recovery.

## Offline indexes

- `community_catalog.json` indexes **1,283 community skills** with source commit, source path, author, license, description, search terms, and the corresponding local Markdown asset.
- `community/` contains the 1,283 bundled `SKILL.md` instruction files used for offline retrieval; `community_bundle.zip` preserves the complete upstream `skills/` tree, including each skill's scripts, references, assets, and accompanying license/attribution files.
- `knowledge_index.json` contains **32 searchable operational knowledge entries** covering Kali/rootfs discovery, package managers, Android permissions, storage, PRoot, PTY, Flutter, GitHub Actions, local GGUF inference, recovery, cancellation, and release verification.
- Both indexes include English and Arabic search terms so Arabic tasks can retrieve relevant local guidance.
- `AgentSkillLibrary` and `AgentKnowledgeIndex` rank entries locally; the orchestrator injects only bounded relevant context to leave room for GGUF generation.
- The knowledge index is reference material. Live PTY output, exit codes, registered tool schemas, and actual runtime state remain authoritative.

## Runtime and trust model

- The local model remains the sole author of execution plans and recovery proposals. Invalid model output is reported rather than replaced with a guessed heuristic plan.
- Skill Markdown and knowledge records are inert context; they are never executed and cannot grant tool permissions, approve protected actions, or bypass Android root authorization.
- The community bundle is synced from [hummbl-io/agent-skills](https://github.com/hummbl-io/agent-skills). The generated catalog pins the exact upstream commit and preserves per-skill source/author/license metadata. The complete upstream `LICENSE` and `ATTRIBUTION.md` are preserved inside `community_bundle.zip`.
- The existing 15 `obra/superpowers` skills retain their MIT attribution/license, and Zion's 9 operational skills remain original Zion documentation. Do not treat the HUMMBL bundle's top-level license as overriding any per-skill NVIDIA/community license noted in `ATTRIBUTION.md`.

## Zion-native skills

- `local-runtime-discovery.md`
- `linux-package-inventory.md`
- `pty-evidence-debugging.md`
- `flutter-ci-repair.md`
- `local-model-planning.md`
- `android-storage-inventory.md`
- `evidence-driven-recovery.md`
- `defensive-network-inventory.md`
- `git-safe-recovery.md`

## Attribution

Upstream project: https://github.com/obra/superpowers  
License for the upstream skills: MIT; see `LICENSE`. Zion-native skill documents are original Zion documentation.
