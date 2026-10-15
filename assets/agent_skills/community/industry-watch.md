---
name: industry-watch
description: Track bleeding-edge AI announcements from NVIDIA, Google, Apple, Microsoft, AWS, Cloudflare, OpenAI, and open-source model/tool providers.
version: 0.1.1
execution-mode: advisory
argument-hint: "[--vendor nvidia|google|apple|microsoft|aws|cloudflare|openai|opensource|all] [--depth quick|full] [--focus models|infra|policy|tools|all]"
category: backend-infra
status: candidate
---
# Industry Watch

Track AI announcements across the major players and open-source ecosystem. Complements `[anthropic-watch]` (which covers Anthropic exclusively) and `[competitive-intel]` (which does positioning analysis). This skill is pure signal collection -- what shipped, what changed, what's coming.

## HUMMBL Market Intel Frame

Default reporting structure for material findings:

1. `position`
   The vendor's explicit stance, doctrine, policy claim, or strategic framing.
2. `action`
   The concrete launch, restriction, rollout, partnership, product move, or enforcement step.
3. `reaction`
   The measurable market, customer, policy, competitor, or public response.
4. `routing_implication`
   What HUMMBL should do with the signal: monitor, adopt, avoid, escalate, or convert into another artifact.

Use this frame by default for:

- policy-sensitive announcements
- safety or cybersecurity launches
- market-moving model releases
- major partner ecosystem changes
- regulatory or public-trust signals

Do not stop at "what happened." Convert the finding into operator-usable routing.

## When to Use
- Morning routine (pair with `[anthropic-watch]` and `[daily-research]`)
- Before architecture decisions involving non-Anthropic services
- Before investor updates or competitive positioning
- When user asks "what's new in AI" or "what did X announce"
- Weekly cadence minimum; daily during conference seasons (GTC, I/O, WWDC, Build, re:Invent, dev week)

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

## Vendors & Sources

### NVIDIA
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `developer.nvidia.com/blog` | CUDA, TensorRT, Triton, NIM releases |
| P1 | `github.com/NVIDIA` | Open-source releases (TensorRT-LLM, NeMo, RAPIDS) |
| P2 | `nvidianews.nvidia.com` | Earnings, partnerships, hardware launches |
| P2 | GTC announcements | New GPUs, inference chips, software stack |
| P3 | `x.com/ABORCHEZ` (Jensen) | Strategic signals, product teasers |

**Watch for**: New GPU architectures, inference optimization libraries, NIM microservice updates, CUDA toolkit releases, TensorRT-LLM versions, pricing/availability of H100/B100/GB200.

### Google
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `blog.google/technology/ai` | Gemini releases, model cards |
| P1 | `ai.google.dev/changelog` | API changes, SDK updates |
| P1 | `cloud.google.com/blog` | Vertex AI, TPU, GKE AI features |
| P1 | `github.com/google-deepmind` | Research code drops |
| P2 | `deepmind.google/research` | Papers, breakthroughs |
| P2 | `developers.googleblog.com` | Android AI, Firebase AI, Chrome AI |
| P3 | `x.com/Google_AI` | Launch threads |

**Watch for**: Gemini model updates (Ultra/Pro/Flash/Nano), context window changes, Vertex AI pricing, TPU availability, NotebookLM features, AI Studio changes, Android on-device AI, Project Astra/Mariner.

### Apple
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `machinelearning.apple.com` | ML research papers and releases |
| P1 | `developer.apple.com` | WWDC, Core ML, ML frameworks |
| P1 | `github.com/apple/ml-stable-diffusion` (and other ml-* repos) | Open-source ML tools |
| P2 | `apple.com/newsroom` | Product announcements with AI features |
| P3 | `x.com/Apple` | Launch signals |

**Watch for**: Apple Intelligence updates, on-device model improvements, Core ML changes, Private Cloud Compute updates, Siri/LLM integration, Foundation Models framework, MLX updates.

### Microsoft
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `azure.microsoft.com/en-us/blog` | Azure AI, OpenAI Service updates |
| P1 | `github.com/microsoft` | Guidance, ONNX, DeepSpeed, Semantic Kernel, AutoGen |
| P1 | `devblogs.microsoft.com` | Copilot, VS Code AI, .NET AI |
| P2 | `blogs.microsoft.com/ai` | Strategic AI announcements |
| P2 | `microsoft.com/en-us/research` | MSR papers, Phi model releases |
| P3 | `x.com/Microsoft` | Launch threads |

**Watch for**: Phi model releases, Azure OpenAI Service changes, Copilot features, AutoGen/Semantic Kernel updates, DeepSpeed versions, ONNX Runtime, Windows AI features, Copilot+ PC updates.

### AWS
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `aws.amazon.com/blogs/machine-learning` | SageMaker, Bedrock, Inferentia |
| P1 | `aws.amazon.com/blogs/aws` | Service launches, pricing |
| P1 | `docs.aws.amazon.com/bedrock` | Bedrock model availability, API changes |
| P2 | `aboutamazon.com/news` | Strategic announcements |
| P2 | `github.com/aws` | Open-source tools, CDK constructs |
| P3 | re:Invent / re:Mars announcements | Annual roadmap signals |

**Watch for**: Bedrock model additions/deprecations, Trainium/Inferentia chip updates, SageMaker features, Nova model updates, pricing changes, new foundation model providers on Bedrock, PartyRock updates.

### Cloudflare
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `blog.cloudflare.com` | Workers AI, AI Gateway, Vectorize |
| P1 | `developers.cloudflare.com/workers-ai` | Model catalog, API changes |
| P1 | `github.com/cloudflare` | Open-source AI tools |
| P2 | `x.com/CloudflareDev` | Feature launches |

**Watch for**: Workers AI model additions, AI Gateway features, Vectorize updates, edge inference pricing, new model partnerships, R2 + AI workflows, Constellation changes.

### OpenAI
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `openai.com/blog` | Model releases, product launches |
| P1 | `platform.openai.com/docs/changelog` | API changelog |
| P1 | `github.com/openai` | Open-source releases (Whisper, Triton, Evals, Codex) |
| P2 | `openai.com/safety` | Safety research, evals |
| P2 | `openai.com/policies` | Usage policies, terms changes |
| P3 | `x.com/OpenAI` | Launch threads, teasers |
| P3 | `x.com/sama` (Sam Altman) | Strategic signals |

**Watch for**: GPT model releases/deprecations, API pricing changes, function calling updates, Assistants API changes, Codex CLI, image/video/audio model updates, enterprise features, rate limit changes.

### Open Source AI Ecosystem
| Priority | Source | Signal |
|----------|--------|--------|
| P1 | `huggingface.co/blog` | Transformers, model releases, leaderboards |
| P1 | `github.com/meta-llama` | Llama model releases |
| P1 | `mistral.ai/news` | Mistral model releases |
| P1 | `ollama.com/blog` | Ollama releases, model support |
| P1 | `github.com/ggerganov/llama.cpp` | Quantization, inference engine updates |
| P2 | `github.com/vllm-project/vllm` | vLLM serving engine |
| P2 | `github.com/mozilla-Ocho/llamafile` | llamafile releases |
| P2 | `ai.meta.com/blog` | Meta AI research, model cards |
| P2 | `qwenlm.github.io` (Alibaba Qwen) | Qwen model releases |
| P2 | `github.com/deepseek-ai` | DeepSeek model releases |
| P2 | `github.com/01-ai` (Yi) | Yi model releases |
| P2 | `stability.ai/news` | Stable Diffusion, image/video models |
| P2 | `github.com/huggingface/text-generation-inference` | TGI updates |
| P2 | `github.com/xai-org` | Grok open weights |
| P3 | `arxiv.org` (cs.CL, cs.AI, cs.LG) | Key papers with code |
| P3 | Hugging Face Open LLM Leaderboard | Benchmark shifts |
| P3 | `x.com/huggingface` | Community signals |
| P3 | `github.com/LostRuins/koboldcpp` | Local inference alternatives |
| P3 | `github.com/TabbyML/tabby` | Open-source code completion |
| P3 | `github.com/continuedev/continue` | Open-source AI IDE |

**Watch for**: New open-weight model releases (especially >70B), quantization breakthroughs, inference speed records, new architectures (MoE, SSM), licensing changes, benchmark-topping models, LoRA/fine-tuning tooling, MCP server ecosystem growth.

## Focus Areas

| Focus | Covers | Why It Matters |
|-------|--------|---------------|
| **models** | New models, weights, benchmarks, deprecations, pricing | What's available, what's competitive |
| **infra** | GPUs, chips, cloud services, inference engines, serving | What to build on, cost optimization |
| **policy** | AI regulation, safety commitments, licensing, terms | Compliance, governance positioning |
| **tools** | SDKs, frameworks, IDEs, agents, MCP, developer experience | Build toolchain, integration opportunities |
| **all** | Everything above | Full sweep |

## Execution

### Supadata CLI Setup

Before running, ensure the Supadata key is available:

```bash
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"
```

The `supadata.py` CLI at `~/bin/supadata.py` wraps all endpoints. Commands used in this skill:
- `scrape <url>` — fetch page as clean Markdown (1 credit)
- `map <url>` — discover all URLs on a site (1 credit)
- `transcript <url> --text` — extract video transcript (1 credit)
- `metadata <url>` — get video metadata without full transcript (1 credit)

### quick (default -- 5 minutes)

Headline scan. Hit P1 sources only for specified vendors (or all). Use Supadata to fetch actual content from the top 2-3 vendor blogs.

1. **For each vendor** (or all if `--vendor all`):
   ```
   WebSearch "<vendor> AI announcement 2026" (last 7 days)
   WebSearch "<vendor> model release 2026" (last 7 days)
   ```
   Then for the 1-2 most promising P1 URLs found:
   ```
   python3 ~/bin/supadata.py scrape "<vendor-blog-url>"
   ```

2. **Open source sweep**:
   ```
   WebSearch "open source AI model release 2026" (last 7 days)
   WebSearch "huggingface trending model" (last 7 days)
   ```

3. **Output**: Findings table (see Output Format)

### full (15-20 minutes)

Deep sweep across all priorities for all vendors. Use Supadata to scrape every P1 blog/changelog directly, and crawl docs sites for API/schema changes.

1. **All quick steps**

2. **Per-vendor deep dive** — scrape P1 sources directly:

   **NVIDIA**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://developer.nvidia.com/blog"
   python3 ~/bin/supadata.py scrape "https://nvidianews.nvidia.com"
   ```

   **Google**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://blog.google/technology/ai"
   python3 ~/bin/supadata.py scrape "https://ai.google.dev/changelog"
   python3 ~/bin/supadata.py scrape "https://cloud.google.com/blog"
   ```

   **Apple**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://machinelearning.apple.com"
   python3 ~/bin/supadata.py scrape "https://developer.apple.com"
   ```

   **Microsoft**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://azure.microsoft.com/en-us/blog"
   python3 ~/bin/supadata.py scrape "https://devblogs.microsoft.com"
   ```

   **AWS**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://aws.amazon.com/blogs/machine-learning"
   python3 ~/bin/supadata.py scrape "https://aws.amazon.com/blogs/aws"
   ```

   **Cloudflare**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://blog.cloudflare.com"
   ```

   **OpenAI**:
   ```bash
   python3 ~/bin/supadata.py scrape "https://openai.com/blog"
   python3 ~/bin/supadata.py scrape "https://platform.openai.com/docs/changelog"
   ```

3. **Open source deep dive**:
   ```
   WebSearch "huggingface new model trending May 2026"
   WebSearch "llama.cpp release" (last 14 days)
   WebSearch "vllm release" (last 14 days)
   WebSearch "ollama new model" (last 14 days)
   WebSearch "open weight model benchmark 2026"
   WebSearch "MCP server new" (last 14 days)
   ```
   Then scrape key project pages:
   ```bash
   python3 ~/bin/supadata.py scrape "https://huggingface.co/blog"
   python3 ~/bin/supadata.py scrape "https://ollama.com/blog"
   python3 ~/bin/supadata.py scrape "https://mistral.ai/news"
   ```

4. **Cross-cutting signals**:
   ```
   WebSearch "AI model benchmark leaderboard 2026"
   WebSearch "AI inference cost comparison 2026"
   WebSearch "AI regulation update 2026" (last 14 days)
   WebSearch "AI agent framework new 2026"
   ```

5. **Conference check** (if in season):
   ```
   WebSearch "GTC 2026" OR "Google I/O 2026" OR "WWDC 2026" OR "Microsoft Build 2026"
   ```
   If keynotes are on YouTube, extract transcripts:
   ```bash
   python3 ~/bin/supadata.py transcript "<keynote-youtube-url>" --text
   ```

6. **Site crawling** — for documentation sites to detect new APIs/endpoints:
   ```bash
   python3 ~/bin/supadata.py map "https://docs.aws.amazon.com/bedrock" 2>/dev/null | head -20
   python3 ~/bin/supadata.py map "https://platform.openai.com/docs" 2>/dev/null | head -20
   ```

7. **Output**: Full findings + analysis + organization implications

## Output Format

```
Industry Watch | {date} | {vendors} | {focus} | {depth}
=======================================================

## Headlines (last 7 days)

| # | Date | Vendor | Category | Finding | Source | Impact |
|---|------|--------|----------|---------|--------|--------|
| 1 | ... | NVIDIA | model | ... | P1: developer.nvidia.com | ... |
| 2 | ... | Meta | model | ... | P1: github.com/meta-llama | ... |

## Breaking Changes / Action Required
(Only if applicable)
- [ ] ACTION: ...

## Model Landscape Shifts
(New models that change competitive dynamics)
| Model | Provider | Parameters | License | Benchmark vs Previous Best |
|-------|----------|-----------|---------|---------------------------|
| ... | ... | ... | ... | ... |

## Infrastructure Updates
(Cloud/GPU/inference changes affecting cost or capability)
- ...

## Open Source Momentum
(Notable community releases, adoption signals)
- ...

## Implications for your organization
- Governance: does any vendor's policy move create opportunity?
- Architecture: do we need to update any adapter or integration?
- Competitive: how does this affect our positioning vs Credo AI, Holistic AI, etc.?
- Partner: does this affect our Anthropic partnership strategy?

## Next Check
Suggested: {date + cadence}
```

## Conference Calendar (key dates to increase cadence)

| Event | Typical Timing | Vendor | Watch Intensity |
|-------|---------------|--------|-----------------|
| GTC | March | NVIDIA | Daily during event |
| Google I/O | May | Google | Daily during event |
| WWDC | June | Apple | Daily during event |
| Microsoft Build | May | Microsoft | Daily during event |
| AWS re:Invent | Nov-Dec | AWS | Daily during event |
| Cloudflare Birthday Week | Sep | Cloudflare | Daily during event |
| OpenAI Dev Day | Annual | OpenAI | Daily during event |
| NeurIPS | Dec | Open Source | Daily during event |
| ICML | July | Open Source | Daily during event |

## Cadence Recommendations

| Situation | Frequency | Depth |
|-----------|-----------|-------|
| Normal operations | Weekly | quick |
| Conference season | Daily | full for relevant vendor |
| Pre-investor update | Day-of | full --vendor all |
| Architecture decision | As needed | full --vendor specific |
| Competitive positioning work | Twice weekly | full |

## What to Persist

After a **full** run with significant findings:
- Update memory if a model release or deprecation affects our stack
- Post to bus if findings are actionable for other agents
- Suggest `[decision-log]` if findings change architecture direction
- Suggest `[send-email] dan` if findings affect business strategy
- Update `[anthropic-watch]` comparison if a competitor matches/exceeds Anthropic capability

## Skill Chains

| After this skill... | Consider... |
|--------------------|-------------|
| Major model release | `[competitive-intel]` for positioning, `[anthropic-watch]` for Anthropic response |
| Pricing change | `[runway]` to recalculate costs |
| New open-source model | Evaluate for $REMOTE_HOST deployment (check params vs 48GB M4 Pro) |
| Infrastructure update | `[arch-diagram]` if it changes our stack |
| Policy/regulation news | `[daily-research] --ingest` to add to governance knowledge base |
| Conference week | `[loop] 1d [industry-watch] --vendor <vendor> --depth full` |
| Multiple vendor moves | `[investor-update]` or `[changelog-digest]` for the team lead |
| benchmark newly announced models via free-tier routing | `[reasoning-router]` (`route`) |
