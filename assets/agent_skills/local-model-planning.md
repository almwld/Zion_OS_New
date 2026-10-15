---
name: local-model-planning
description: Keep the local GGUF model authoritative for plans and recovery proposals.
---
# Local Model Planning
1. Supply the original task, registered tool schemas, relevant memory, and only the best-ranked skill/knowledge excerpts.
2. Request structured JSON with bounded step count and exact registered tool/parameter names.
3. Validate model output; when invalid, surface a precise error and ask the model to regenerate.
4. Never replace a missing or invalid model plan with a hand-written heuristic plan.
5. Record cancellation, timeout, token budget, and native inference failures as distinct states.
Keep prompt context small enough to leave generation room in the model's actual context window.