---
name: workers-kv
description: Manage Cloudflare KV namespaces — key-value storage with TTL, listing, and bulk operations from Workers
version: 0.1.0
execution-mode: advisory
argument-hint: "[--namespace <name>] [--action get|put|list|delete|bulk]"
category: backend-infra
status: candidate
---
# workers-kv | Cloudflare KV Namespace Management

## When to Use
- Storing configuration or feature flags accessible at the edge
- Caching computed values with TTL expiration
- Bulk-importing or exporting key-value pairs
- Listing keys with prefix filtering for namespace inspection

## Execution

### 1. Parse Arguments
- `--namespace <name>`: KV namespace name
- `--action get|put|list|delete|bulk`: operation to perform
- If no namespace given, list all via `wrangler kv namespace list`

### 2. get — Retrieve a Key
- Run `npx wrangler kv key get <key> --namespace-id <id>`
- Decode value; detect JSON vs plain text vs binary
- Report metadata if present

### 3. put — Write a Key
- Validate value size (< 25 MiB per value)
- Set TTL with `--ttl <seconds>` if requested
- Run `npx wrangler kv key put <key> <value> --namespace-id <id>`
- Optionally attach metadata JSON

### 4. list — Enumerate Keys
- Run `npx wrangler kv key list --namespace-id <id> --prefix <p>`
- Paginate with `--cursor` for large namespaces
- Report key count, expiration timestamps, and metadata presence

### 5. delete — Remove a Key
- Confirm key exists before deletion
- Run `npx wrangler kv key delete <key> --namespace-id <id>`
- Warn if key has active TTL (would expire anyway)

### 6. bulk — Batch Operations
- Read JSON file of `[{key, value, ttl?}, ...]` for puts
- Read JSON array of keys for deletes
- Run `npx wrangler kv bulk put <file> --namespace-id <id>`
- Report success/failure count per entry

### 7. Verify Binding
- Confirm `[[kv_namespaces]]` block in `wrangler.toml`
- Check `binding`, `id`, and `preview_id` are set

## Output Format

```
workers-kv | <namespace-name>

## Action: <get|put|list|delete|bulk>

## Namespace
- ID: <namespace-id> | Binding: KV
- Keys: 1,247 | Storage: 8.2 MiB

## Result
| Key          | Value      | TTL    | Metadata |
|--------------|------------|--------|----------|
| config:theme | dark       | 3600s  | yes      |
| flag:beta    | true       | -      | no       |

## Bulk
- Put: 150 succeeded, 0 failed
- Delete: 12 succeeded, 1 failed (key not found)

## Binding
- wrangler.toml: configured / missing

## Verdict
READY / NAMESPACE_NOT_FOUND / BINDING_MISSING / SIZE_LIMIT_EXCEEDED
```

## Skill Chains
- After namespace setup -> `[cloudflare]` to verify Worker integration
- Before deployment -> `[deploy-checklist]` to confirm prerequisites
