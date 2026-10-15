---
name: model-card
description: Generate ML model cards documenting capabilities, limitations, training data, and ethical considerations
version: 0.1.0
execution-mode: advisory
argument-hint: "<model-path> [--format markdown|json]"
category: backend-infra
status: candidate
---
# model-card | ML Model Card Generation for Documentation & Transparency

## When to Use
- Documenting a model before deployment or public release
- Satisfying responsible-AI and compliance documentation requirements
- Providing downstream users with capabilities, limitations, and risks
- Onboarding new team members to a model's intended use

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<model-path>` (HF repo or local dir)
- `--format`: `markdown` | `json` (default `markdown`)
- `--output`: output file path (default `./MODEL_CARD.md` or `./model_card.json`)

### 2. Extract Model Metadata
- Load `config.json` for architecture, parameter count, hidden size, layers
- Read `tokenizer_config.json` for tokenizer type and vocab size
- Check for existing `README.md` or `config` metadata fields
- Identify model family (encoder, decoder, encoder-decoder, embedding)

### 3. Probe Capabilities & Limitations
- Run model on 5 canonical prompts (QA, summarization, code, reasoning, multilingual)
- Record outputs and flag failure modes (hallucination, refusal, format errors)
- Estimate context window from config max_position_embeddings
- Note known limitations (cutoff date, language coverage, task suitability)

### 4. Document Training & Data (Best-Effort)
- Extract training data references from config or paper (if available)
- Record intended use cases and out-of-scope uses
- List ethical considerations: bias risks, dual-use concerns, content safety
- Include environmental impact estimate if training cost data available

### 5. Generate Card
- **Markdown**: produce structured MD with sections (Model Details, Intended Use, Training Data, Evaluation, Limitations, Ethical Considerations)
- **JSON**: produce structured JSON matching HF model card schema
- Write to output path and print summary

## Output Format

```
model-card | <model-path>

## Configuration
- Format: markdown | Output: ./MODEL_CARD.md

## Model Card Summary
| Field                | Value                          |
|----------------------|--------------------------------|
| Model name           | <name>                         |
| Architecture         | <arch>                         |
| Parameters           | 7.0 B                          |
| Context window       | 4096                           |
| Tokenizer            | <tokenizer>                    |
| Intended use         | text generation, QA            |
| Out-of-scope         | medical advice, legal counsel  |
| Known limitations    | English-only, pre-2023 cutoff  |

## Sections Generated
- Model Details
- Intended Use & Out-of-Scope
- Training Data
- Evaluation Results
- Limitations
- Ethical Considerations
- Environmental Impact

## Verdict
CARD GENERATED | ./MODEL_CARD.md | 7 sections
```

## Skill Chains
- After card generation -> `[ml-evaluate]` to fill in evaluation metrics
- After card generation -> `[ai-safety-check]` to audit ethical claims
- Before card generation -> `[mlops-deploy]` to ensure model is finalized
- For generate model card text via free-tier inference -> `[reasoning-router]` (`route`)
