---
name: webhook-manage
description: Create, test, and monitor webhook integrations with retry logic, payload inspection, and delivery tracking
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--action create|test|monitor|list] [--url URL] [--event EVENT]"
category: dev-tools
status: candidate
---
# Webhook Manage

Manage webhook integrations end-to-end: create webhook configurations, test delivery with sample payloads, monitor delivery success rates, and inspect payload formats. Stores webhook definitions in `_state/webhooks/config.jsonl` and delivery logs in `_state/webhooks/deliveries.jsonl`.

## When to Use
- Setting up a new webhook integration for alerts, CI events, or bus notifications
- Testing whether a webhook endpoint receives and processes payloads correctly
- Debugging failed webhook deliveries or unexpected payload formats
- Monitoring delivery success rates and identifying unreliable endpoints

## Execution
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=webhook-manage] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Parse `$ARGUMENTS` for action (default: `list`), URL, and event type.
2. For `create` action:
   - Define webhook: URL, event types to subscribe to, secret for HMAC signing, retry policy.
   - Validate URL is reachable with a HEAD request.
   - Write configuration to `_state/webhooks/config.jsonl`.
3. For `test` action:
   - Load webhook config for the specified URL or event.
   - Generate a sample payload matching the event schema.
   - Send the payload via HTTP POST with appropriate headers (Content-Type, X-Webhook-Signature).
   - Report response status, latency, and response body.
   - Test with malformed payload to verify error handling.
4. For `monitor` action:
   - Read delivery logs from `_state/webhooks/deliveries.jsonl`.
   - Calculate delivery success rate, average latency, and retry frequency.
   - Identify endpoints with high failure rates or increasing latency.
5. For `list` action:
   - Show all configured webhooks with their event subscriptions and status.

## Output Format
```
Webhook Manage | action

## Webhooks
| URL | Events | Status | Success Rate | Avg Latency |
|-----|--------|--------|-------------|-------------|
| {url} | {events} | {ACTIVE|FAILING|DISABLED} | {N%} | {Nms} |

## Test Results (if action=test)
- Endpoint: {url}
- Status: {HTTP status code}
- Latency: {Nms}
- Response: {truncated body}
- HMAC Verification: {PASS|FAIL|N/A}

## Delivery Health (if action=monitor)
- Total deliveries (24h): N
- Success rate: N%
- Failed deliveries: N
- Retries triggered: N
- Slowest endpoint: {url} ({Nms avg})

## Issues
- {any failing endpoints or delivery problems}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains

### Mandatory

None — webhook management; external but reversible.

### Advisory

- → `[api-design]` (for endpoint patterns when designing webhook API)
- → `[mock-server]` (stand up a test receiver for webhook testing)
- → `[alert-rule]` (notify on webhook failures after setup)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator approval required for production webhooks
- **T4 (Probationary)**: BLOCKED (external integration management)
- **Operator**: Override any restriction
