---
provider-specific: true
name: vendor-gen-eval
description: Full benchmarking, evaluation, and testing program for the vendor-neutral generation system (hummbl-gen CLI + gen-image/gen-photoshoot/gen-marketplace-cards skills). Covers latency, quality, cost, free-tier limits, 1Password integration, regression detection, and CI gates.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action benchmark|eval|test|report|all] [--provider <name>] [--model <id>] [--suite <id>] [--iterations N]"
category: backend-infra
status: candidate
providers:
  required: [python]
  optional: [eval-spec(md-scored), yaml-ls]
---
# Vendor-Gen Eval | Benchmarking & Evaluation Program

Comprehensive testing program for the `hummbl-gen` CLI and three skills (`gen-image`, `gen-photoshoot`, `gen-marketplace-cards`). Follows fleet patterns from `eval-suite`, `benchmark`, `load-test`.

## Architecture

```
vendor-gen-eval
├── benchmarks/          # Microbenchmarks (CLI overhead, request latency, retry logic)
├── evaluations/         # Quality eval suites (text + image) across providers/models
├── load-tests/          # Concurrent load, rate-limit handling, free-tier quota mapping
├── integration/         # 1Password auto-discovery, fallback chains, skill chains
├── regression/          # Baseline comparison, alerting thresholds
├── ci/                  # Gates for merge/promotion
└── reporting/           # Unified reports, trends, dashboards
```

---

## 1. Benchmarking (Microbenchmarks)

**Tool**: `benchmark` skill + custom harness

| Target | Metric | Threshold | Notes |
|--------|--------|-----------|-------|
| CLI cold start (`providers`) | mean latency | < 200ms | stdlib imports only |
| CLI warm (`models --provider groq`) | mean latency | < 150ms | no network |
| `_try_op_read` (cache hit) | mean latency | < 5ms | in-memory cache |
| `_try_op_read` (cache miss, 1P unlocked) | p99 latency | < 3s | subprocess + op binary |
| HTTP request (Groq) | p50 latency | < 1.5s | network-dependent |
| HTTP request (OpenRouter) | p50 latency | < 2s | |
| Retry backoff (429) | total time | 9s ± 1s | 3 attempts: 3s + 6s |
| Retry backoff (5xx) | total time | 9s ± 1s | same |
| Image download (2MB) | mean latency | < 5s | includes urllib overhead |

**Execution**:
```bash
# Run all microbenchmarks (saves baselines to _state/benchmarks/vendor-gen/)
python -m benchmark vendor_gen_eval.benchmarks.cli_cold_start --iterations 100 --save
python -m benchmark vendor_gen_eval.benchmarks.http_request --provider groq --iterations 50 --save
python -m benchmark vendor_gen_eval.benchmarks.op_read --cached --iterations 1000 --save
python -m benchmark vendor_gen_eval.benchmarks.op_read --uncached --iterations 20 --save
python -m benchmark vendor_gen_eval.benchmarks.image_download --iterations 10 --save
```

**Regression gate**: Mean latency increase > 15% over baseline → FAIL

---

## 2. Evaluations (Quality Suites)

**Tool**: `eval-suite` skill + custom scorers

### 2.1 Text Generation Eval Suite (`eval-vendor-text-v1`)

**Cases**: 15 prompts covering:
- Factual QA (3)
- Code generation (3)
- Summarization (3)
- Creative writing (3)
- Instruction following (3)

**Scorers** (weighted):
| Scorer | Weight | Method |
|--------|--------|--------|
| Accuracy | 0.30 | LLM-as-judge against reference |
| Format compliance | 0.20 | Schema/regex validation |
| Conciseness | 0.15 | Token count vs baseline |
| Instruction adherence | 0.20 | LLM-as-judge |
| Safety (no PII/hallucination) | 0.15 | LLM-as-judge + keyword filter |

**Providers × Models matrix** (discovered at runtime):
| Provider | Free Models to Test (auto-discover via `models --free`) |
|----------|---------------------------------------------------------|
| openrouter | `:free` variants (gemini, llama, qwen, deepseek) |
| groq | llama-3.1-8b, llama-3.3-70b, mixtral, gemma |
| cerebras | llama-3.1-8b, llama-3.3-70b |
| together | llama-3.1-8b, mixtral, deepseek |
| mistral | mistral-small, mistral-medium |
| google | gemini-1.5-flash, gemini-1.5-pro |
| nvidia | nemotron, llama variants |
| huggingface | zephyr, openchat, neural-chat |

**Run**:
```bash
python -m eval-suite run --suite eval-vendor-text-v1 --provider all --auto-1password
```

**Pass gate**: Weighted score ≥ 3.5/5.0 per model; no model regresses > 0.5 points vs baseline.

### 2.2 Image Generation Eval Suite (`eval-vendor-image-v1`)

**Cases**: 10 prompts covering:
- Product photography (3)
- Logo/icon (2)
- Illustration (2)
- Diagram/chart (1)
- Style transfer (1)
- Text rendering (1)

**Scorers** (weighted):
| Scorer | Weight | Method |
|--------|--------|--------|
| Prompt adherence | 0.35 | LLM-as-judge (vision) vs prompt |
| Visual quality | 0.25 | LLM-as-judge (sharpness, artifacts) |
| Composition | 0.20 | LLM-as-judge |
| Brand compliance | 0.15 | Color palette check (Grove/Verderer) |
| Technical validity | 0.05 | File format, dimensions, corruption |

**Providers × Models** (image-capable only, auto-discover):
| Provider | Image Models (free tier) |
|----------|--------------------------|
| openrouter | gemini-2.0-flash-exp:free, google/gemini-2.5-flash-image-preview:free |
| together | black-forest-labs/FLUX.1-schnell-free, stabilityai/stable-diffusion-xl-base-1.0 |
| huggingface | fal-ai/flux-schnell, black-forest-labs/FLUX.1-schnell |
| google | gemini-2.0-flash-exp (image), imagen-3 |
| nvidia | stabilityai/sdxl, nvidia/edify-image (if free) |

**Run**:
```bash
python -m eval-suite run --suite eval-vendor-image-v1 --provider all --auto-1password
```

**Pass gate**: Weighted score ≥ 3.0/5.0 per model; output files valid PNG/JPEG.

---

## 3. Load Testing (Concurrent & Free-Tier Mapping)

**Tool**: `load-test` skill + custom quota mapper

### 3.1 Concurrency Test
```bash
# 10 concurrent workers, 5 RPS each, 60s duration
python -m load-test "https://api.groq.com/openai/v1/chat/completions" \
  --rps 50 --duration 60 --concurrency 10 \
  --header "Authorization: Bearer $GROQ_API_KEY" \
  --method POST --body-file test-payload.json
```

**Metrics**: p50/p90/p95/p99 latency, error rate, achieved RPS

### 3.2 Free-Tier Quota Mapping (Critical for Ops)

**Per-provider quota discovery** (run weekly, store in `_state/vendor-gen/quotas.json`):

| Provider | Free Tier Limit | Reset Cadence | Measured RPS Limit |
|----------|-----------------|---------------|-------------------|
| groq | 14,400 req/day (llama-3.1-8b) | Daily UTC 00:00 | ~100 RPM |
| openrouter | $1 credits → ~varies by model | Monthly | Model-dependent |
| cerebras | Unlimited (rate-limited) | N/A | ~200 RPM |
| together | 100 req/hour (free models) | Hourly | ~1 RPM |
| huggingface | 1,000 req/day (router) | Daily | ~70 RPM |
| google | 1,500 req/day (flash) | Daily | ~100 RPM |
| mistral | 100 req/day (experiment) | Daily | ~5 RPM |
| nvidia | 1,000 credits → varies | Monthly | Model-dependent |

**Quota stress test**: Ramp RPS until 429 rate, record limit, back off. Store limits.

**Run**:
```bash
python vendor_gen_eval/load_quota_mapper.py --all-providers --auto-1password
```

---

## 4. Integration Testing

| Test | Description | Expected |
|------|-------------|----------|
| 1P auto-discovery (unlocked) | `models --provider groq` with 1P unlocked | Key resolved, request succeeds |
| 1P auto-discovery (locked) | Same with 1P locked | Graceful fallback error |
| 1P cache hit | Second call within same process | < 5ms, no `op` subprocess |
| 1P cache miss → hit | Two processes, second hits cache | First: 1-3s, second: <5ms |
| Fallback: env var wins | `GROQ_API_KEY=xxx` + 1P has different key | Env var used |
| Fallback: manual `op run` | `op run --env-file op.env -- hummbl-gen ...` | Keys injected, requests work |
| Skill chain: gen-photoshoot → gen-image | `--mode product_shot` → image gen | Files saved, prompts use brand tokens |
| Skill chain: gen-marketplace-cards → gen-image | `--scope full-set` → 13 image calls | 13 files, correct naming |
| Custom vendor | `--base-url https://api.example/v1 --api-key-env KEY` | Request routed correctly |
| Dry-run all commands | `--dry-run` on chat/image/models | JSON printed, no network |
| Error formatting | 401, 429, 500, timeout, network | Structured error, no key leak |

**Run**:
```bash
python -m pytest vendor_gen_eval/integration/ -v --tb=short
```

---

## 5. Regression Detection

**Baseline storage**: `_state/benchmarks/vendor-gen/` + `_state/eval-results/vendor-gen/`

| Artifact | Location | Updated |
|----------|----------|---------|
| CLI microbenchmarks | `_state/benchmarks/vendor-gen/*.json` | On `--save` |
| Text eval results | `_state/eval-results/vendor-gen/text/*.jsonl` | Per run |
| Image eval results | `_state/eval-results/vendor-gen/image/*.jsonl` | Per run |
| Quota maps | `_state/vendor-gen/quotas.json` | Weekly |
| Load test baselines | `_state/benchmarks/load/vendor-gen/` | On `--save` |

**Regression thresholds**:
- Microbenchmarks: mean latency +15% → FAIL
- Text eval: weighted score -0.5 points → FAIL
- Image eval: weighted score -0.5 points → FAIL
- Load test: p95 +20% OR error rate +1% → FAIL
- Quota limits: measured limit < 80% of expected → WARN

---

## 6. CI Gates

**GitHub Actions workflow**: `.github/workflows/vendor-gen-eval.yml`

```yaml
on: [push, pull_request]
jobs:
  microbenchmarks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - run: python -m benchmark vendor_gen_eval.benchmarks.all --compare
  
  eval-text:
    runs-on: ubuntu-latest
    env:
      OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
      GROQ_API_KEY: ${{ secrets.GROQ_API_KEY }}
      # ... all provider keys as repo secrets
    steps:
      - run: python -m eval-suite run --suite eval-vendor-text-v1 --provider all
      - run: python -m eval-suite report --suite eval-vendor-text-v1 --gate 3.5
  
  eval-image:
    runs-on: ubuntu-latest
    env: {same secrets}
    steps:
      - run: python -m eval-suite run --suite eval-vendor-image-v1 --provider all
      - run: python -m eval-suite report --suite eval-vendor-image-v1 --gate 3.0
  
  integration:
    runs-on: ubuntu-latest
    # Requires 1P service account token for CI
    env:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
    steps:
      - run: python -m pytest vendor_gen_eval/integration/ -v
  
  quota-check:
    runs-on: ubuntu-latest
    schedule: ['0 2 * * 1']  # Weekly Monday 2am
    steps:
      - run: python vendor_gen_eval/load_quota_mapper.py --all-providers
```

**Merge gate**: All jobs PASS + no regression flags.

---

## 7. Reporting & Dashboards

### 7.1 Unified Report (`vendor-gen-eval report`)

```bash
python vendor_gen_eval/report.py --last-run --format markdown
```

Output sections:
- Microbenchmark summary (table + regression flags)
- Text eval leaderboard (model × provider, scores, latency, cost)
- Image eval leaderboard
- Free-tier quota status (current usage vs limit, projected exhaustion)
- Integration test matrix (PASS/FAIL)
- Trend sparklines (last 10 runs)

### 7.2 Trends Dashboard (`_state/vendor-gen/trends.json`)

Appended each run:
```json
{
  "timestamp": "2026-08-16T18:00:00Z",
  "git_sha": "abc123",
  "benchmarks": {"cli_cold_start_ms": 145, "http_groq_p50_ms": 1100},
  "text_eval": {"groq:llama-3.1-8b": 4.2, "openrouter:gemini-flash:free": 3.9},
  "image_eval": {"openrouter:gemini-flash:free": 3.5, "together:flux-schnell": 3.8},
  "quotas": {"groq_rpm": 95, "openrouter_daily_pct": 42}
}
```

### 7.3 Cost Tracking

Since we use free tiers, cost = 0, but track:
- Requests per provider per day
- Credits consumed (OpenRouter, NVIDIA)
- Projected days until quota exhaustion

---

## 8. Execution Commands

### Full Program (All)
```bash
# One-shot full run (takes ~45 min with all providers)
python vendor_gen_eval/run_all.py --auto-1password --save-baselines
```

### Individual Components
```bash
# Microbenchmarks only
python -m benchmark vendor_gen_eval.benchmarks.all --iterations 100 --compare --save

# Text eval only
python -m eval-suite run --suite eval-vendor-text-v1 --provider groq,openrouter,cerebras --auto-1password

# Image eval only
python -m eval-suite run --suite eval-vendor-image-v1 --provider openrouter,together,huggingface --auto-1password

# Load + quota mapping
python vendor_gen_eval/load_quota_mapper.py --all-providers --auto-1password --save

# Integration tests
python -m pytest vendor_gen_eval/integration/ -v

# Regression report
python vendor_gen_eval/report.py --compare-baselines --format markdown > eval-report.md
```

### CI Local Simulation
```bash
act push --job microbenchmarks
act push --job eval-text
# etc.
```

---

## 9. Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| `[vendor-gen-eval] benchmark` | `[decision-log]` (record provider selection rationale) |
| `[vendor-gen-eval] eval` | `[model-compare]` (detailed side-by-side) |
| `[vendor-gen-eval] load` | `[alert-rule]` (quota exhaustion alerts) |
| Regression detected | `[perf-profile]` / `[prompt-lab]` (iterate) |
| Quota limits mapped | `[cost-forecast]` (project monthly spend if paid) |
| New provider added | `[skill-create]` (extend provider map) |
| Streaming inference benchmark | `[stream-inference]` to measure TTFT/throughput on Cloudflare Workers AI (`python ~/bin/stream_test.py <model> --prompt "test" --use-gateway`) |

---

## 10. Artifacts to Create

```
~/.agents/skills/vendor-gen-eval/
├── SKILL.md                    # This file
├── run_all.py                  # Orchestrator entry point
├── report.py                   # Unified report generator
├── benchmarks/
│   ├── __init__.py
│   ├── cli_cold_start.py
│   ├── http_request.py
│   ├── op_read.py
│   └── image_download.py
├── eval_suites/
│   ├── eval-vendor-text-v1.jsonl
│   └── eval-vendor-image-v1.jsonl
├── load_quota_mapper.py
├── integration/
│   ├── test_1password.py
│   ├── test_fallbacks.py
│   ├── test_skill_chains.py
│   └── test_custom_vendor.py
└── ci/
    └── github-actions-template.yml
```

---

## Quick Start

```bash
# 1. Ensure 1Password unlocked with your mapped items
# 2. Run discovery to verify providers work
python ~/.agents/skills/gen-image/scripts/hummbl_gen.py models --provider groq --free --auto-1password

# 3. Run text eval (fastest, no image downloads)
python -m eval-suite run --suite eval-vendor-text-v1 --provider groq --auto-1password

# 4. Run full program when ready
python vendor_gen_eval/run_all.py --auto-1password --save-baselines
```

---

## Guardrails

- **Spend guardrail**: All evals use free tiers only. Paid models require explicit `--allow-paid` flag.
- **Privacy guardrail**: No prompts with PII/secrets in eval suites. Use synthetic data.
- **Rate guardrail**: Load tests respect measured quota limits; back off on 429.
- **Key hygiene**: Keys never logged, never in reports, 1P auto-discovery only reads — never writes.