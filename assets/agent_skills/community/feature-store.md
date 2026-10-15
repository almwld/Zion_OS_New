---
name: feature-store
description: Manage ML feature stores and data pipelines for consistent training and serving. [Maps to CO15.]
version: 0.1.0
execution-mode: advisory
argument-hint: <feature-name-or-pipeline-spec>
category: backend-infra
status: candidate
---
# Feature Store Management Command

Manage machine learning feature stores to ensure consistency between training and serving, track feature lineage, and maintain data quality for ML pipelines.

## When to Use
- Setting up new ML projects requiring feature management
- When user mentions feature consistency or data pipeline concerns
- Tracking feature versions and dependencies
- Ensuring training-serving parity in ML systems
- Managing feature updates and backfilling

## Execution

### 1. Parse Feature Specification
Accept either:
- Specific feature name or version to manage
- Feature pipeline specification or definition
- Feature store configuration or connection details
- Query for existing features or statistics

### 2. Connect to Feature Store
Establish connection to the feature store backend:
- Validate connection parameters and credentials
- Check feature store health and availability
- Verify schema compatibility and access permissions

### 3. Execute Feature Operations
Based on the argument, perform appropriate actions:
- **Feature Retrieval**: Get feature values for training or serving
- **Feature Registration**: Define new features with metadata
- **Materialization**: Compute and store feature values
- **Validation**: Check feature quality, completeness, and drift
- **Lineage Tracking**: Trace feature origins and transformations
- **Versioning**: Manage feature updates and backward compatibility

### 4. Ensure Training-Serving Parity
Verify that features used for training match those used for serving:
- Compare feature definitions between environments
- Validate transformation logic consistency
- Check for temporal leakage or data leakage risks
- Confirm point-in-time correctness for historical features

### 5. Generate Feature Report
Provide insights into feature usage, quality, and management status.

## Output Format
```
Feature Store | <feature-name-or-pipeline-spec>
═════════════════════════════
Feature Store: <backend-type> (<connection-info>)
Requested: <timestamp>

## Summary
- Total Features Managed: <count>
- Active Feature Pipelines: <count>
- Features Ready for Serving: <count>
- Data Quality Score: <score>/100

## Feature Details
<if specific-feature-requested>
### Feature: <feature-name> v<version>
**Type**: <numerical/categorical/text/embedding>
**Entity**: <user-id/product-id/etc>
**Description**: <feature-description>
**Data Type**: <float/int/string/etc>
**Default Value**: <value-or-null>
**Null Percentage**: <percentage>%

**Pipeline**:
  - Source: <source-table-or-stream>
  - Transformation: <sql/python/etc>
  - Schedule: <cron/streaming/batch>
  - Freshness: <last-updated> (<age>)

**Statistics** (latest window):
  - Mean: <value> | Std: <value>
  - Min: <value> | Max: <value>
  - Unique Values: <count> (if categorical)
  - Distribution: <histogram-description>

**Usage**:
  - Training Samples: <count> (last week)
  - Serving Requests: <count> (last day)
  - Models Using: <list-of-model-ids>
<else>
### Feature Store Overview
**Features by Domain**:
  - <domain-name>: <count> features
  - <domain-name>: <count> features
  ...

**Recent Activity**:
  - Features Added: <count> (last 24h)
  - Features Updated: <count> (last 24h)
  - Pipelines Run: <count> (last 24h)
  - Backfill Jobs: <count> (last 24h)

**Data Quality Issues**:
  - Features with High Nulls: <count> (>50% null)
  - Stale Features: <count> (>24h old)
  - Schema Changes: <count> (requiring update)
## End If

## Training-Serving Parity Check
<if parity-checked>
**Status**: <pass/fail>
<if failed>
**Mismatches Found**:
  1. **Feature**: <feature-name>
     **Issue**: <description-of-mismatch>
     **Impact**: <training-serving-skew-risk>
     **Fix**: <recommended-action>
<else>
✅ Training and serving feature definitions are consistent
## End If
<else>
Parity check not performed
## End If

## Recommendations
PRIORITY: <most-critical-feature-store-issue>
NEXT: <suggested-action>
Consider [ml-train] for model training with these features
Estimated effort: <S/M/L>

## Base120 Context
- Primary: **CO15** (Configuration Matrix - systematically managing feature combinations)
- Related: **DE5** (Finding vital few features), **SY13** (Designing reliable ML systems)

## After Completion
Naturally chains to: Use features in [ml-train], or continue feature store management
