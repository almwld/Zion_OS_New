---
name: workers-queue
description: Manage Cloudflare Queues — producer/consumer patterns, dead letter queues, and batch processing from Workers
version: 0.1.0
execution-mode: advisory
argument-hint: "[--queue <name>] [--action produce|consume|monitor|dlq]"
category: backend-infra
status: candidate
---
# workers-queue | Cloudflare Queues Management

## When to Use
- Decoupling long-running work from request handling in Workers
- Implementing producer/consumer patterns with batch processing
- Monitoring queue depth, throughput, and consumer lag
- Configuring dead letter queues (DLQ) for failed messages

## Execution

### 1. Parse Arguments
- `--queue <name>`: Queue name
- `--action produce|consume|monitor|dlq`: operation to perform
- If no queue given, list all via `wrangler queues list`

### 2. produce — Send Messages
- Run `npx wrangler queues send <queue> --data "<json>"`
- For Worker-based production: `await env.QUEUE.send(JSON.stringify(payload))`
- Report batch ID and message count

### 3. consume — Process Messages
- Generate consumer handler: iterate `batch.messages`, process, `msg.ack()`
- Configure `max_batch_size`, `max_batch_timeout`, `max_retries`
- Deploy consumer Worker and verify it binds to the queue

### 4. monitor — Inspect Queue Health
- Query queue metrics via Cloudflare API
- Report: messages queued, throughput (msg/s), consumer lag
- Alert if queue depth exceeds `--threshold` (default 1000)
- Show age of oldest message

### 5. dlq — Configure Dead Letter Queue
- Create DLQ queue: `wrangler queues create <queue>-dlq`
- Set `dead_letter_queue` in consumer configuration
- Report messages in DLQ and their failure reasons
- Provide replay command to requeue messages

### 6. Verify Bindings
- Confirm `[[queues.producers]]` and `[[queues.consumers]]` in `wrangler.toml`
- Check `binding`, `queue`, and `dead_letter_queue` are set

## Output Format

```
workers-queue | <queue-name>

## Action: <produce|consume|monitor|dlq>

## Queue
- Name: email-sender | Messages: 42 | Consumers: 1
- Max batch: 10 | Max retries: 3 | DLQ: email-sender-dlq

## Produce
- Messages sent: 50 | Batch ID: abc-123 | Status: success

## Consume
- Worker: email-worker | Batch: 10 | Acked: 10 | Failed: 0 | 120 ms/msg

## Monitor
| Metric         | Value    |
|----------------|----------|
| Depth          | 42       |
| Throughput     | 8 msg/s  |
| Consumer lag   | 1.2s     |
| Oldest message | 3.4s ago |

## DLQ
- Queue: email-sender-dlq | Messages: 3 | Top: SMTP timeout (2), Invalid addr (1)

## Binding
- wrangler.toml: configured / missing

## Verdict
READY / QUEUE_NOT_FOUND / BINDING_MISSING / CONSUMER_LAG_HIGH
```

## Skill Chains
- After queue setup -> `[cloudflare]` to verify Worker integration
- Before deployment -> `[deploy-checklist]` to confirm prerequisites
