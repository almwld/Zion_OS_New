---
name: workers-r2
description: Manage Cloudflare R2 object storage — buckets, objects, lifecycle policies, and S3-compatible API
version: 0.1.0
execution-mode: advisory
argument-hint: "[--bucket <name>] [--action upload|download|list|lifecycle]"
category: backend-infra
status: candidate
providers:
  required: [python]
---
# workers-r2 | Cloudflare R2 Object Storage Management

## When to Use
- Storing large blobs (images, backups, datasets) without egress fees
- Uploading or downloading objects via Worker or S3-compatible API
- Configuring lifecycle rules for automatic tiering or deletion
- Migrating assets from S3 to R2 with S3-compatible endpoints

## Execution

### 1. Parse Arguments
- `--bucket <name>`: R2 bucket name
- `--action upload|download|list|lifecycle`: operation to perform
- If no bucket given, list all via `wrangler r2 bucket list`

### 2. upload — Put an Object
- Validate file exists and size is within R2 limits (5 TiB per object)
- For multipart, split files > 100 MiB into 5-MiB parts
- Run `npx wrangler r2 object put <bucket>/<key> --file <path>`
- Optionally set `--content-type` and custom metadata

### 3. download — Get an Object
- Run `npx wrangler r2 object get <bucket>/<key> --file <path>`
- Verify checksum (MD5) matches stored ETag
- Report object size and content-type

### 4. list — Enumerate Objects
- Run `npx wrangler r2 object list <bucket> --prefix <p>`
- Paginate with `--cursor` for large buckets
- Report key, size, last-modified, and ETag per object

### 5. lifecycle — Configure Rules
- Generate lifecycle JSON:
  ```json
  {"rules": [{"id": "archive-old", "status": "enabled",
   "filter": {"prefix": "logs/"}, "expiration": {"days": 90}}]}
  ```
- Apply via R2 API or Terraform `cloudflare_r2_bucket_lifecycle`
- Warn on rules that would delete data without backup

### 6. Verify Binding
- Confirm `[[r2_buckets]]` block in `wrangler.toml`
- Check `binding`, `bucket_name`, and `jurisdiction` (if applicable)

## Output Format

```
workers-r2 | <bucket-name>

## Action: <upload|download|list|lifecycle>

## Bucket
- Name: assets | Location: auto | Objects: 3,421
- Storage: 12.7 GiB | Egress: $0.00

## Upload
- Key: images/logo.png | Size: 142 KiB
- ETag: a1b2c3... | Content-Type: image/png
- Status: success

## List
| Key            | Size    | Modified           | ETag   |
|----------------|---------|--------------------|--------|
| images/logo    | 142 KiB | 2024-01-15T10:00Z  | a1b2.. |
| data/export    | 8.1 MiB | 2024-01-14T22:30Z  | d4e5.. |

## Lifecycle
- Rule: archive-old | Status: enabled | Expiration: 90 days
- Affected objects: 1,200 (prefix: logs/)

## Binding
- wrangler.toml: configured / missing

## Verdict
READY / BUCKET_NOT_FOUND / BINDING_MISSING / UPLOAD_FAILED
```

## Skill Chains
- After bucket setup -> `[cloudflare]` to verify Worker integration
- After backup upload -> `[backup-verify]` to validate integrity
- Before deployment -> `[deploy-checklist]` to confirm prerequisites
