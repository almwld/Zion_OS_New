---
name: observability-setup
description: Instrument a service with distributed tracing, metrics, and structured logging. Set up OpenTelemetry, configure exporters, verify telemetry is flowing. Use when adding observability to a new service or upgrading an existing one's instrumentation.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--service <name>] [--backend jaeger|tempo|datadog|stdout] [--traces] [--metrics] [--logs]"
category: backend-infra
status: candidate
---
# observability-setup | Distributed Tracing, Metrics & Structured Logging

Instrument a service end-to-end with OpenTelemetry so traces, metrics, and
structured logs flow to a backend. Advisory: propose changes, show diffs,
operator approves before editing application code.

## When to Use
- Adding observability to a new service, or upgrading ad-hoc logging/metrics to OTel
- Fleet tracing mesh onboarding; log-trace correlation post-incident

## Arguments
| Flag | Default | Purpose |
|------|---------|---------|
| `--service <name>` | (detect) | Service name used as resource attribute |
| `--backend jaeger\|tempo\|datadog\|stdout` | `stdout` | Exporter / collector target |
| `--traces` `--metrics` `--logs` | on if none given | Enable each signal individually |

## Execution

### 1. Identify the service and its language/framework
```bash
for m in package.json go.mod requirements.txt pyproject.toml Cargo.toml pom.xml; do
  find . -maxdepth 2 -name "$m" -not -path '*/node_modules/*' 2>/dev/null
done
```
Record language, framework, DB driver, HTTP client, message bus. Set
`service.name` from `--service` or the repo/directory name.

### 2. Select the OpenTelemetry SDK and instrumentation libraries
| Stack | SDK | Auto-instrumentation |
|-------|-----|----------------------|
| Python (FastAPI/Flask/Django) | `opentelemetry-sdk` | `...-instrumentation-{fastapi,flask,django}`, `requests`, `sqlalchemy` |
| Node (Express/Next) | `@opentelemetry/sdk-node` | `@opentelemetry/auto-instrumentations-node` |
| Go (net/http, gin, echo) | `go.opentelemetry.io/otel` | `otelhttp`, `otelgrpc`, `otelsql` |
| Java (Spring) | `opentelemetry-sdk` | `opentelemetry-spring-boot-starter` |

Prefer **auto-instrumentation** first; add manual spans only where it doesn't
cover a key operation.

### 3. Add tracing spans for key operations
Auto-instrumentation covers HTTP handlers and most DB drivers. Add manual spans
for business logic and external calls not auto-instrumented.
```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("process_order") as span:
    span.set_attribute("order.id", order_id)
    charge_payment(order_id)  # child span auto-created
```
Node: bootstrap in `tracing.js` imported BEFORE the app (`node --require
./tracing.js app.js`) — `NodeSDK` + `getNodeAutoInstrumentations()` + `OTLPTraceExporter`.

### 4. Add metrics (request count, latency histogram, error rate)
Define RED metrics (Rate, Errors, Duration) per key endpoint.
```python
from opentelemetry import metrics
meter = metrics.get_meter(__name__)
req_counter = meter.create_counter("http.server.request.total", unit="1")
req_duration = meter.create_histogram("http.server.request.duration", unit="ms")
# In an HTTP middleware: record start, call handler, then
# req_counter.add(1, attrs); req_duration.record(elapsed_ms, attrs)
# attrs = {method, route, status_code}
```

### 5. Add structured logging with trace context correlation
Integrate with the existing logging framework — do **not** replace it. Inject
`trace_id`/`span_id` so logs pivot to traces:
```python
from opentelemetry import trace
ctx = trace.get_current_span().get_span_context()
if ctx.is_valid:  # structlog processor / loguru sink / stdlib Filter
    event["trace_id"] = f"{ctx.trace_id:032x}"
    event["span_id"] = f"{ctx.span_id:016x}"
```

### 6. Configure exporters for the chosen backend
All OTLP backends use `OTEL_TRACES_EXPORTER=otlp`; only the endpoint differs:
| Backend | `OTEL_EXPORTER_OTLP_ENDPOINT` |
|---------|-------------------------------|
| Jaeger / Tempo / Datadog | `http://<backend>:4317` (jaeger / tempo / datadog-agent) |
| stdout | `OTEL_TRACES_EXPORTER=console` + `OTEL_METRICS_EXPORTER=console` (dev) |

Metrics → Prometheus or same OTLP collector. Logs → Loki/ELK via collector;
app logs stay on stdout, collector forwards.

### 7. Verify telemetry is flowing
```bash
curl -sS -o /dev/null http://localhost:8080/health
curl -sS "http://jaeger:16686/api/traces?service=${SERVICE}&limit=5" | jq '.data | length'
```
Checklist:
- [ ] Trace with service name appears in backend; child spans nest correctly
- [ ] Metrics expose `http.server.request.total` and `.duration`
- [ ] Log records carry non-empty `trace_id` / `span_id`
- [ ] A forced error yields an ERROR log linked to an `error`-status span

### 8. Document the instrumentation setup
Write a short `OBSERVABILITY.md` (or README section): signals emitted and where
exported, env vars (dev/prod), local stdout workflow, manual-span rationale,
trace lookup by `trace_id`.

## Boundaries
- **Does not replace existing logging frameworks** — integrates via trace-context
  injection (structlog/loguru/stdlib stay).
- **No alerting rules** — use `[alert-rule]`. **No perf profiling** — use
  `[perf-profile]`. Traces show latency structure, not why.
- **Read-only on existing app code** except instrumentation additions. Propose
  refactors separately.

## Output Format
```
observability-setup | <service> (backend: <backend>)
## Detected Stack: <lang>/<framework>/<db>/<http-client>
## Instrumentation Plan
- Traces: <auto libs> + <N manual> | Metrics: <counters/histograms> | Logs: <fw> + ctx
## Changes / Exporter / Verification / Docs
- [ ] <file>: <change> | Backend: <b> @ <url> | Trace/Metrics/Logs: y/n | OBSERVABILITY.md: y/n
```

## Skill Chains
- Before -> `[observability-audit]` | After -> `[alert-rule]` (alert on metrics)
- Latency outlier -> `[perf-profile]` | SLOs -> `[slo-define]`
