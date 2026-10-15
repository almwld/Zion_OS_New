---
name: data-profile
description: Profile datasets for column types, nullability, cardinality, distributions, outliers, and quality flags
version: 0.1.0
execution-mode: advisory
argument-hint: "<dataset> [--sample-size 10000] [--format json|html]"
category: data-science
status: candidate
---
# data-profile | Dataset Profiler

## When to Use
- Onboarding a new dataset before modeling or pipeline design
- Detecting data drift between snapshots or environments
- Generating quality flags for governance workflows
- Producing documentation for data consumers

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<dataset>` path or table identifier
- `--sample-size N`: rows to sample for expensive stats (default 10000, 0 = full scan)
- `--format json|html`: output format (default json)

### 2. Load Dataset
- Connect to source (file, database, dataframe in memory)
- Determine total row count and byte size via metadata where possible
- Draw a representative sample using reservoir sampling if full scan is costly

### 3. Column-Level Statistics
- Infer type: integer, float, string, datetime, boolean, categorical
- Compute null count and null percentage
- Compute cardinality, unique ratio, and top-5 frequent values
- For numerics: min, max, mean, median, stdev, quartiles
- For strings: min/max length, empty-string count, pattern hints

### 4. Distribution and Outliers
- Build histograms for numeric columns (fixed-width bins)
- Flag outliers via IQR rule (values beyond 1.5*IQR from Q1/Q3)
- Detect skew and flag heavily skewed distributions
- Estimate entropy for categorical columns

### 5. Quality Flags
- High-null (>50%): flag for review
- Constant column (cardinality 1): flag as candidate for removal
- Type mismatch: flag rows that fail inferred type
- Duplicate-key check on declared primary keys

### 6. Emit Profile
- Write profile to `_state/profiles/<dataset>.<format>`
- Include summary, per-column stats, and quality flags

## Output Format

```
data-profile | <dataset> (sample=10000)

## Summary
- Rows: 1,204,330 (sampled 10,000) | Columns: 12 | Size: 482 MB

## Column Profiles
| Column     | Type      | Nulls  | Unique  | Min/Max        | Outliers |
|------------|-----------|--------|---------|----------------|----------|
| id         | integer   | 0%     | 10000   | 1 / 10000      | 0        |
| email      | string    | 0.1%   | 9982    | len 5-42       | -        |
| amount     | float     | 2.3%   | 8721    | 0.01 / 999.99  | 47       |

## Quality Flags
- HIGH_NULL: notes (52% null) -> review
- CONSTANT: status (cardinality 1) -> candidate for removal
- DUPLICATE_KEY: id -> 0 duplicates PASS

## Verdict
PASS | 12 columns profiled, 2 quality flags raised
```

## Skill Chains
- After profiling -> `[data-quality]` to enforce rules on flagged columns
- After profiling -> `[data-catalog]` to enrich catalog metadata
- Before profiling -> `[etl-design]` to inform schema decisions
