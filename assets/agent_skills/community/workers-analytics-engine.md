---
name: workers-analytics-engine
description: Configure Cloudflare Analytics Engine — time-series data ingestion, SQL queries via Workers Analytics, and dashboard integration
version: 0.1.0
execution-mode: advisory
argument-hint: "[--dataset <name>] [--action ingest|query|dashboard]"
category: backend-infra
status: candidate
---
# workers-analytics-engine | Cloudflare Analytics Engine Configuration

## When to Use
- Ingesting time-series events (page views, API calls, IoT metrics) at the edge
- Querying high-cardinality analytics data with SQL via Workers Analytics
- Building dashboards on top of Analytics Engine datasets
- Replacing expensive third-party analytics with edge-native ingestion

## Execution

### 1. Parse Arguments
- `--dataset <name>`: Analytics Engine dataset name
- `--action ingest|query|dashboard`: operation to perform
- If no dataset given, list configured datasets from `wrangler.toml`

### 2. ingest — Configure Data Pipeline
- Verify `[[analytics_engine_datasets]]` binding in `wrangler.toml` (binding = "ANALYTICS", dataset = "events")
- Generate ingestion snippet: `env.ANALYTICS.writeDataPoint({ blobs: [...], doubles: [...], indexes: [...] })`
- Validate limits: blobs (max 20), doubles (max 20), indexes (max 1)

### 3. query — Run SQL via Workers Analytics
- Generate query Worker: `const res = await env.ANALYTICS.query("SELECT ..."); return Response.json(await res.array())`
- Validate SQL syntax against Analytics Engine SQL dialect
- Report row count and query latency

### 4. dashboard — Integrate with Grafana or Custom UI
- Generate Grafana data source config or JSON API endpoint for custom dashboards
- Include sample queries for common visualizations (timeseries, top-N, heatmap)

### 5. Validate Schema and Limits
- Confirm dataset exists and binding is active
- Check data retention (default 90 days, max 1 year)
- Warn on high-cardinality indexes that may exceed limits

## Output Format

```
workers-analytics-engine | <dataset-name>

## Action: <ingest|query|dashboard>

## Dataset
- Binding: ANALYTICS | Dataset: events
- Retention: 90 days | Status: active

## Ingest
- Fields: blobs[2] doubles[2] indexes[1]
- Sample event: { url: "/api", country: "US", rt: 42, status: 200 }
- Snippet: generated | Limits: OK

## Query
```sql
SELECT blob1, SUM(double1) FROM events
WHERE timestamp > NOW() - INTERVAL 1 HOUR
GROUP BY blob1
```
- Rows: 15 | Latency: 230 ms

## Dashboard
- Type: grafana | Endpoint: /analytics/query
- Panels: 4 (timeseries, top-N, gauge, table)

## Binding
- wrangler.toml: configured / missing

## Verdict
READY / DATASET_NOT_FOUND / BINDING_MISSING / QUERY_FAILED / CARDINALITY_HIGH
```

## Skill Chains
- After dataset setup -> `[cloudflare]` to verify Worker integration
- After dashboard creation -> `[dashboard-check]` to validate panels
- Before deployment -> `[deploy-checklist]` to confirm prerequisites
