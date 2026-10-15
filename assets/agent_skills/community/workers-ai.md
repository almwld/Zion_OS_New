---
name: workers-ai
description: Deploy and manage Cloudflare Workers AI models — text generation, embeddings, image classification, and speech recognition via Workers AI bindings
version: 0.1.0
execution-mode: advisory
argument-hint: "[--model <model-id>] [--task text|embed|image|speech]"
category: backend-infra
status: candidate
---
# workers-ai | Cloudflare Workers AI Model Management

## When to Use
- Adding AI inference to a Cloudflare Worker without provisioning GPUs
- Generating text or embeddings via managed models (Llama, Mistral, etc.)
- Running image classification or speech recognition at the edge
- Comparing model latency and cost across Workers AI tasks

## Execution

### 1. Parse Arguments
- `--model <model-id>`: specific model (e.g. `@cf/meta/llama-3-8b-instruct`)
- `--task text|embed|image|speech`: task category to scope model selection
- If no model given, list available models for the requested task

### 2. Inspect or Generate Binding
- Check `wrangler.toml` / `wrangler.jsonc` for existing `ai` binding
- If missing, add:
  ```toml
  [ai]
  binding = "AI"
  ```
- Validate binding name matches Worker code references

### 3. Generate Worker Snippet
Produce task-appropriate handler:
- **text**: `env.AI.run(model, { prompt, max_tokens })`
- **embed**: `env.AI.run(model, { text })` returning float array
- **image**: `env.AI.run(model, { image })` with base64 input
- **speech**: `env.AI.run(model, { audio })` with transcription output

### 4. Validate Model Availability
- Query `https://api.cloudflare.com/client/v4/accounts/{id}/ai/models/search`
- Confirm model supports the requested task type
- Flag deprecated or preview-only models

### 5. Deploy and Smoke Test
- Run `npx wrangler deploy`
- Send a minimal test request to the Worker route
- Verify response shape matches task expectation

## Output Format

```
workers-ai | <model-id>

## Binding
- Binding: AI | Status: present / added
- wrangler.toml updated: yes / no

## Model
- ID: @cf/meta/llama-3-8b-instruct
- Task: text | Context: 8k tokens
- Status: GA / Beta / Deprecated

## Worker Snippet
```js
export default {
  async fetch(req, env) {
    const res = await env.AI.run("<model>", { prompt: "..." });
    return Response.json(res);
  }
};
```

## Smoke Test
- Request: POST /ai | Latency: 420 ms
- Response: 200 OK | Tokens: 32

## Verdict
READY / BINDING_MISSING / MODEL_UNAVAILABLE / DEPLOY_FAILED
```

## Skill Chains
- After deployment -> `[cloudflare]` to verify Worker route
- After embeddings task -> `[rag-pipeline]` to consume vectors
- Before deployment -> `[deploy-checklist]` to confirm prerequisites
- After deployment -> `[stream-inference]` to test live streaming inference via `python ~/bin/stream_test.py --model <model> --prompt "test" [--use-gateway]`
- After deployment -> `[usage-monitor]` to track Neuron consumption via `python ~/bin/usage_monitor.py status`
- For execute inference via free-tier providers after deployment -> `[reasoning-router]` (`python ~/bin/reasoning_router.py probe --provider cloudflare`)
