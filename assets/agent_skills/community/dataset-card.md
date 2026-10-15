---
name: dataset-card
category: data-science
description: >-
  Generate a dataset card documenting provenance, composition, quality metrics,
  known biases, licensing, and recommended usage. Modeled on Mitchell et al.
  (2018) Model Cards and Gebru et al. (2021) Datasheets for Datasets. Use when
  publishing, sharing, or onboarding a new dataset.
version: 0.1.0
status: candidate
execution-mode: advisory
argument-hint: "[--dataset <path-or-url>] [--format json|yaml|markdown] [--schema <schema-file>]"
---

# dataset-card

Generate a dataset card: a structured record of provenance, composition,
quality, known biases, licensing, and recommended usage — human-readable and
machine-parseable. Drawn from **Model Cards** (Mitchell et al., 2018) and
**Datasheets for Datasets** (Gebru et al., 2021).

**Advisory**: produces a card for human review. Does not modify the dataset,
enforce policy, or gate publication.

**Use when:** publishing/releasing a dataset, onboarding consumers, registering
in a catalog, responding to an audit, or capturing dataset state.

**Do not use for:** data-quality audits with thresholds (`data-quality`),
distribution profiling (`data-profile`), or data transformation. Documents
what was observed; cite existing runs rather than re-deriving.

## Arguments

| Flag | Req | Default | Description |
|------|-----|---------|-------------|
| `--dataset` | yes | — | Path or URL to the dataset. |
| `--format` | no | `markdown` | `json`, `yaml`, or `markdown`. |
| `--schema` | no | inferred | Schema file for expected columns/types. |

## Workflow

1. **Identify the dataset.** Location, format(s), byte/row/column size,
   schema. Load supplied schema or infer from a sample.
2. **Document provenance.** Creator, date, upstream source(s), collection
   method, stated purpose, version, parent datasets.
3. **Analyze composition.** Row/column counts, types, missing-value rates,
   distribution stats. Cite `data-profile` when available.
4. **Assess quality.** Duplicate-row rate, outliers, schema-conformance,
   type-error counts. Cite `data-quality` when available. Summarizes only.
5. **Identify biases.** Demographic skew, temporal gaps, geographic coverage,
   selection bias. **Document what was checked and how** — explicitly.
6. **Document licensing.** License type, attribution, restrictions,
   commercial-use. State "unknown" plainly.
7. **Define recommended usage.** Appropriate uses, known limitations (tied
   to composition/bias), discouraged uses.
8. **Generate the card.** Emit in requested format; all formats share fields.
9. **Emit a machine-readable manifest.** Compact scalar fields for pipelines
   and drift detection.

## Dataset card template

Required fields must be present even if "unknown" or "not assessed". Empty
sections are preferable to omitted ones.

```markdown
# Dataset Card: <name>

## Metadata
- card_version: <semver>           - card_generated: <ISO-8601>
- card_generator: dataset-card v0.1.0
- dataset_version: <version or "unversioned">  - dataset_checksum: <sha256 or "n/a">
- format: <csv|parquet|json|sqlite|other>

## 1. Overview
- name: <name>         - description: <one-paragraph summary>
- purpose: <intended use per creators>

## 2. Provenance
- creator: <person/team/org>       - created_date: <date or range>
- source: <upstream origin — URL/system/description>
- collection_method: <API|scrape|survey|manual|derived|...>
- parent_datasets: <list or "none">  - version_lineage: <history or "initial">

## 3. Composition
- rows: <count>   - columns: <count>   - size_bytes: <count>
- schema: <inline or ref to file>
- data_types: <per-column type summary>
- missing_value_rates: <per-column fraction>
- distribution_summary: <numeric: min/max/mean/median; categorical: cardinality+top-k>
- profile_ref: <data-profile run-id or "not run">

## 4. Quality
- duplicate_row_rate: <fraction>  - outlier_counts: <per-column or "not assessed">
- schema_conformance: <fraction or "not assessed">
- type_error_counts: <per-column mismatches>
- quality_ref: <data-quality run-id or "not run">  - notes: <free text>

## 5. Bias Assessment
- attributes_checked: <columns examined>
- demographic_skew: <findings or "not applicable">
- temporal_coverage: <range and gaps>
- geographic_coverage: <regions or "not applicable">
- selection_bias: <known/suspected effects>
- what_was_not_checked: <unchecked axes — required>

## 6. Licensing
- license: <SPDX id or "unknown">
- attribution_required: <yes|no|unknown>  - commercial_use: <permitted|prohibited|unknown>
- usage_restrictions: <free text>
- third_party_rights: <embedded data/terms or "none">

## 7. Recommended Usage
- appropriate_uses: <list>   - known_limitations: <list, tied to composition/bias>
- discouraged_uses: <list>

## 8. Maintenance
- owner: <maintainer/team>   - update_cadence: <quarterly|ad-hoc|deprecated>
- last_updated: <date>   - change_log: <prior card revisions>
```

## Machine-readable manifest

When `--format` is `markdown`, embed as a fenced YAML block at the card's foot.
When `json`/`yaml`, emit a sibling `<dataset>.manifest.*` file.

```yaml
dataset: <name>        dataset_version: <version>
card_version: 0.1.0    generated: <ISO-8601>
rows: <count>          columns: <count>
size_bytes: <count>    license: <SPDX id or "unknown">
checksum: <sha256 or "n/a">
schema_ref: <path or "inferred">
quality_ref: <path or "not run">
profile_ref: <path or "not run">
```

## Boundaries

- **Does not validate data quality** — use `data-quality` for pass/fail checks.
- **Does not profile distributions** — use `data-profile` for detailed stats.
- **Cards are living documents** — regenerate on dataset change; bump
  `card_version`, update the change log.
- **Bias assessment is incomplete** — document what was checked and how.
  `what_was_not_checked` is required. Absence of findings ≠ absence of bias.

## Output

- Dataset card in requested format + machine-readable manifest.
- Summary noting paths, unfilled fields, and reminder for human sign-off.
