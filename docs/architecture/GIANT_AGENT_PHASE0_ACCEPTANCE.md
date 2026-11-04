# Giant Agent transfer — Phase 0 local inference gate

## Purpose

The Giant Agent ReAct protocol must not be wired into Zion's planner until the
existing on-device GGUF inference path has passed a real-device capability
check. Zion remains local-first. A cloud provider is never an automatic
fallback for a missing or failed local model.

## Current source-level evidence

- `AgentOrchestrator._nativeAiAvailable()` first checks the shared
  `LlamaService.isLoaded` state and then confirms the native session through
  `nativeLoaded`.
- Planning and recovery already fail closed when the local model is not ready;
  they do not invent a plan or execute a heuristic substitute.
- The shared native-session work is tracked separately in Zion PR #78.
- Source inspection is not evidence that a GGUF model actually generates
  correctly on a physical Android device.

## Required device acceptance sequence

1. Load a supported GGUF model once through the Offline AI screen.
2. Navigate to Super Agent and Terminal without unloading/reloading the model.
3. Confirm all screens observe the same native session as ready.
4. Generate a short deterministic response from the local model and verify
   that the output is non-empty, not an error string, and follows the prompt.
5. Run one bounded Super Agent planning request and verify that its JSON plan
   parses and references only registered Zion tools.
6. Cancel an in-progress generation and confirm native generation stops.
7. Navigate away and back; confirm the model remains loaded and no duplicate
   native session is created.
8. Repeat with airplane mode enabled to establish that this path is genuinely
   local and does not silently invoke a cloud provider.

Record device model, Android version, GGUF filename/quantization, model size,
RAM observations, latency, and the exact APK commit used. Do not mark Phase 0
passed without this record.

## Porting gate

Only after Phase 0 passes:

- Adapt Giant Agent's strict ReAct decision envelope to Zion's existing
  `AgentPlan` / `AgentStep` contract.
- Validate JSON structure, registered tool names, argument keys and types,
  unique step IDs, duplicate actions, and bounded step/tool/time budgets.
- Keep `AgentPolicy`, tool-derived permissions, per-step approvals,
  cancellation, timeout handling, recovery limits, memory persistence, and
  audit/event logging authoritative.
- Treat tool output as untrusted data; it cannot grant permissions or issue
  executable instructions by itself.

## Explicit non-goals

- No cloud fallback when local inference is unavailable.
- No copied provider keys, shared JWT secrets, or production credentials.
- No parallel runtime, conversation database, or second policy engine.
- No claim of device acceptance based only on GitHub source checks or CI.
