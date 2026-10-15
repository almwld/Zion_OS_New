---
name: hf-watch
description: Track Hugging Face ecosystem -- new models, trending repos, leaderboard shifts, dataset releases, platform updates, community signals.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--depth quick|full] [--focus models|datasets|spaces|leaderboard|platform|all]"
category: fleet-ops
status: candidate
---
# Hugging Face Watch

Stay current on the Hugging Face ecosystem. Catches model releases, leaderboard shifts, dataset drops, and platform changes within hours/days. Complements `[industry-watch]` (broad) and `[anthropic-watch]` (Anthropic-specific).

## When to Use
- Morning routine (pair with `[industry-watch]` and `[daily-research]`)
- Before choosing a model for local inference (remote-node dormant since 2026-07-01 — use Workstation, Desktop)
- Before starting autoresearch experiments (check if a new baseline exists)
- When user asks "what's trending on HuggingFace?" or "any new models?"
- After major model family releases (Llama, Qwen, Mistral, Gemma)
- Weekly cadence minimum; daily during model release waves

## Sources (ranked by authority)

| Priority | Source | What to Look For |
|----------|--------|-----------------|
| P1 | `huggingface.co/blog` | Official blog -- model releases, platform features, research |
| P1 | `huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard` | Benchmark ranking shifts |
| P1 | `huggingface.co/models?sort=trending` | Trending models (last 7 days) |
| P1 | `github.com/huggingface/transformers/releases` | Transformers library releases |
| P2 | `huggingface.co/datasets?sort=trending` | Trending datasets |
| P2 | `huggingface.co/spaces?sort=trending` | Trending Spaces (demos, tools) |
| P2 | `huggingface.co/blog/leaderboard` | Leaderboard methodology changes |
| P2 | `github.com/huggingface/text-generation-inference/releases` | TGI updates |
| P2 | `github.com/huggingface/tokenizers/releases` | Tokenizer updates |
| P3 | `x.com/huggingface` | Community signals, launch threads |
| P3 | `x.com/ClementDelangue` | CEO signals, strategic direction |
| P3 | `x.com/julien_c` | CTO signals, technical roadmap |
| P3 | `discord.gg/huggingface` | Community discussion, early signals |

## Focus Areas

| Focus | Covers | Why It Matters |
|-------|--------|---------------|
| **models** | New model uploads, trending weights, GGUF quants, fine-tunes | What's available for local inference and autoresearch |
| **datasets** | New datasets, data quality research, FineWeb updates | Training data for autoresearch pipeline |
| **leaderboard** | Open LLM Leaderboard ranking changes, new benchmarks | Competitive positioning, model selection |
| **spaces** | Trending demos, new tools, inference endpoints | Developer tooling, community sentiment |
| **platform** | Hub features, Inference API, Endpoints, pricing | Infrastructure for deployment |
| **all** | Everything above | Full sweep |

## Execution

### quick (default -- 5 minutes)

1. **Trending models sweep:**
   ```
   WebSearch "huggingface trending model this week 2026"
   WebSearch "huggingface new model release 2026" (last 7 days)
   ```

2. **Leaderboard check:**
   ```
   WebSearch "open llm leaderboard changes 2026" (last 7 days)
   WebSearch "huggingface leaderboard new top model"
   ```

3. **Platform updates:**
   ```
   WebSearch "huggingface blog 2026" (last 14 days)
   WebSearch "huggingface transformers release 2026"
   ```

4. **Output**: Findings table (see Output Format)

### full (15-20 minutes)

1. **All quick steps**

2. **Model deep dive:**
   ```
   WebSearch "site:huggingface.co/blog model 2026" (last 14 days)
   WebSearch "GGUF new model quantization 2026"
   WebSearch "huggingface trending model under 10B parameters"
   WebSearch "open weight model release March 2026"
   ```

3. **Dataset sweep:**
   ```
   WebSearch "huggingface new dataset 2026" (last 14 days)
   WebSearch "fineweb update 2026"
   WebSearch "training data quality research 2026"
   ```

4. **Leaderboard deep dive:**
   ```
   WebSearch "open llm leaderboard methodology 2026"
   WebSearch "chatbot arena leaderboard changes 2026"
   WebSearch "LLM benchmark new evaluation 2026"
   ```

5. **Platform + ecosystem:**
   ```
   WebSearch "huggingface inference endpoints update 2026"
   WebSearch "huggingface spaces trending demo 2026"
   WebSearch "transformers library new feature 2026"
   WebSearch "huggingface pricing change 2026"
   ```

6. **Local inference relevance:**
   ```
   WebSearch "best model for RTX 3080 Ti 12GB 2026"
   WebSearch "best model for M4 Pro 48GB Apple Silicon 2026"
   WebSearch "ollama new model support 2026"
   WebSearch "llama.cpp GGUF new quantization type 2026"
   ```

7. **Output**: Full findings + analysis + autoresearch implications

## Output Format

```
HF Watch | {date} | {focus} | {depth}
======================================

## Trending Models (last 7 days)

| # | Model | Provider | Params | License | Notable |
|---|-------|----------|--------|---------|---------|
| 1 | ... | ... | ... | ... | ... |

## Leaderboard Shifts
(New entries, rank changes, benchmark updates)
- ...

## New Datasets
(Relevant to autoresearch, governance, or general training)
- ...

## Platform Updates
(Transformers releases, Hub features, API changes)
- ...

## Local Inference Picks
(Models that fit our hardware: RTX 3080 Ti 12GB, M4 Pro 48GB)

| Model | Quant | VRAM | Use Case | Source |
|-------|-------|------|----------|--------|
| ... | ... | ... | ... | ... |

## Implications for Autoresearch
- Architecture: any new small-model techniques?
- Data: any new datasets worth testing?
- Baselines: any new models that set benchmarks at our scale?

## Implications for HUMMBL
- Governance: model cards, safety, licensing changes
- Compression: new quantization methods in the ecosystem
- Competition: who's releasing what, open-weight trends

## Next Check
Suggested: {date + cadence}
```

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| New model for local inference | Pull via Ollama, benchmark on Desktop |
| New dataset | Evaluate for autoresearch hf_mix pipeline |
| Leaderboard shift | `[competitive-intel]` if it affects positioning |
| Platform change | Update autoresearch or compression tooling |
| Major model release | `[industry-watch]` for broader context |
| test newly discovered HF models via free-tier routing | `[reasoning-router]` (`route`) |

## Cadence

| Situation | Frequency | Depth |
|-----------|-----------|-------|
| Normal operations | Weekly | quick |
| Model release wave (Llama, Qwen, etc.) | Daily | full for model focus |
| Before autoresearch architecture decisions | As needed | full --focus models |
| Before choosing deployment model | As needed | full --focus models |
| Pre-investor update | Day-of | full |
