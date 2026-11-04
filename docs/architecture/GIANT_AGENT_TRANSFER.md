# Giant Agent → Zion OS capability transfer

## Source and scope
This integration is based on the user's `almwld/giant-agent` repository, branch
`feat/chatgpt-experience-foundation`, especially PR #1 and its 2026-11-02
implementation. This is a selective, native Zion integration—not a wholesale
copy of a second application or its branding.

## What Giant Agent contributes
- Strict ReAct decision contract: one JSON object per model turn:
  - `{"type":"tool_call","name":"...","arguments":{...}}`
  - `{"type":"final","answer":"..."}`
- Tool schemas, required-argument checks, type checks, rejection of unexpected
  arguments, bounded execution, duplicate-action prevention, protocol retry,
  timeout and transcript-size budgets.
- A provider abstraction separating model generation from orchestration.
- Authenticated streaming gateway patterns: SSE deltas/errors, model discovery,
  OpenAI Responses API with `store:false`, OpenRouter/Gemini-compatible chat
  streaming, server-managed provider keys and optional BYOK.
- JWT validation (HS256, subject, issuer, audience, expiry and not-before),
  per-subject rate limits, request/attachment limits, and development-only
  static-token authentication.
- Conversation-scoped SQLite persistence, message retry/cancel, search and
  attachment transport.
- Critical operational truth: the Giant Agent branch did not prove production
  gateway deployment, a real identity-provider lifecycle, persistent quotas,
  or a working local GGUF/ONNX/TFLite inference runtime.

## Zion architecture audit and integration decisions
Zion already has a more capable native execution core:
- `AgentRuntime` owns persistent sessions, cancellation, event history and
  Android foreground-service lifecycle.
- `AgentOrchestrator` plans tasks, resolves step dependencies, checks policy,
  requires approval for sensitive effects, executes cancellable tools, records
  step memory, and attempts bounded recovery.
- `ToolRegistry` already exposes AI, browser, data, file, HTTP, Python, shell
  and PTY tools.
- `AgentPolicy` and each tool's declared permissions are authoritative. The
  Giant Agent protocol must never bypass them.
- `LlamaService` is the local inference adapter and must remain first-class.
  Cloud inference must be an optional provider, never a silent fallback that
  claims a local model is loaded.

## Ported in this change
- Offline deterministic `calculator` tool with a bounded arithmetic grammar.
- `get_current_datetime` tool returning device-local time and UTC offset.
- Both are registered in Zion's existing `ToolRegistry`; no duplicate agent
  runtime, second chat UI, database, or provider framework is introduced.

## Integration rules for subsequent phases
1. Adapt strict ReAct JSON decisions into Zion's existing plan/step contract;
   retain policy checks, permission derivation, approval gates, cancellation,
   timeouts, recovery limits and event logging.
2. Add a cloud `AiProvider` adapter only as an explicit optional provider.
   Keep API provider secrets on a server; client-side BYOK must remain in
   Android secure storage and travel only over HTTPS.
3. If a gateway is introduced, authenticate real app identities with short
   lived user JWTs; never ship a shared production token or provider API key.
4. Use bounded SSE parsing and propagate cancellation to upstream requests.
   Distinguish authentication, quota, provider, timeout and network errors.
5. Reuse Zion's existing local persistence/memory where possible. Do not create
   parallel conversation stores without a migration plan.
6. Tool output is untrusted observation data, not instructions. Never treat
   tool output as permission to execute a follow-up action.
7. Never claim that a model, tool, cloud endpoint, or physical-device workflow
   works until it is verified in that environment.

## Explicitly not copied
- Giant Agent's Flutter app shell, application identity, chat UI, SQLite schema,
  and backend service are not transplanted into Zion because Zion already has
  its own runtime, terminal, local model service, memory and system UI.
- No API keys, gateway tokens, signing secrets, or user data are copied.
- No claim is made that cloud providers or production gateway are configured.
