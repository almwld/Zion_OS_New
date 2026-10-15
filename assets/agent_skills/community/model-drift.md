---
name: model-drift
description: Detect and monitor model performance drift over time with statistical validation. [Maps to CO7.]
version: 0.1.0
execution-mode: advisory
argument-hint: <model-path> <baseline-data> <current-data>
category: backend-infra
status: candidate
---
# Model Drift Detection Command

Detect and monitor performance drift in machine learning models by comparing baseline and current data distributions using statistical tests and performance metrics.

## When to Use
- Monitoring deployed models for performance degradation
- When user mentions model accuracy concerns over time
- Comparing model performance before/after data changes
- Setting up automated model retraining triggers
- Auditing model stability in production

## Execution

### 1. Load Data and Model
- Load the trained model from specified path
- Load baseline dataset (training/validation data from when model was performant)
- Load current dataset (recent production or validation data)
- Validate data schema compatibility between datasets

### 2. Detect Data Drift
Compare statistical properties between baseline and current data:
- **Feature Distribution Drift**: Kolmogorov-Smirnov test, PSI (Population Stability Index), JS divergence
- **Covariate Shift**: Changes in input feature distributions
- **Concept Drift**: Changes in relationship between features and target
- **Label Drift**: Changes in target variable distribution
- **Missing Data Patterns**: Changes in missingness mechanisms

### 3. Measure Performance Drift
If labels available in current data:
- Compare key performance metrics (accuracy, precision, recall, F1, etc.)
- Calculate confidence intervals for metric differences
- Statistical significance testing for performance changes
- Analyze performance by segments or cohorts

### 4. Generate Drift Report
Create comprehensive report with:
- Drift detection results and severity scores
- Specific features or concepts showing drift
- Performance impact analysis
- Retraining recommendations

## Output Format
```
Model Drift | <model-path> <baseline-data> <current-data>
═════════════════════════════
Model: <model-type>
Baseline: <baseline-dataset-info>
Current: <current-dataset-info>
Analysis Time: <timestamp>

## Summary
- Overall Drift Severity: <level> (<score>/100)
- Data Drift Detected: <yes/no>
- Performance Drift Detected: <yes/no>
- Retraining Recommended: <yes/no>
- Confidence Level: <percentage>%

## Data Drift Analysis
<if data-drift>
### Features with Significant Drift
1. **Feature**: <feature-name>
   **Drift Metric**: <PSI/KS-value> (<interpretation>)
   **Baseline Distribution**: <description>
   **Current Distribution**: <description>
   **Impact**: <high/medium/low> on model performance
   **Recommended Action**: <investigate/retrain/ignore>

2. **Feature**: <feature-name>
   **Drift Metric**: <PSI/KS-value> (<interpretation>)
   ...
<else>
✅ No significant data drift detected in input features
## End If

<if concept-drift>
### Concept Drift Indicators
1. **Relationship**: <feature-X> vs <target>
   **Baseline Correlation**: <value>
   **Current Correlation**: <value>
   **Change**: <percentage>%
   **Statistical Significance**: <p-value>
   **Interpretation**: <description>
<else>
✅ No significant concept drift detected
## End If

## Performance Drift Analysis
<if labels-available>
### Metric Changes
**Accuracy**: <baseline-value> → <current-value> (<change>%)
  - Significant: <yes/no> (p=<value>)
  - Practical Significance: <minimal/moderate/high>

**Precision**: <baseline-value> → <current-value> (<change>%)
  - Significant: <yes/no> (p=<value>)

**Recall**: <baseline-value> → <current-value> (<change>%)
  - Significant: <yes/no> (p=<value>)

**F1-Score**: <baseline-value> → <current-value> (<change>%)
  - Significant: <yes/no> (p=<value>)
<else>
Labels not available in current data for performance drift analysis
## End If

## Risk Assessment
<if high-drift>
**HIGH RISK**: Significant drift detected requiring immediate attention
**Recommended Actions**:
  1. Investigate data pipeline changes
  2. Consider immediate retraining
  3. Implement data quality checks
<elif moderate-drift>
**MODERATE RISK**: Some drift detected, monitor closely
**Recommended Actions**:
  1. Increase monitoring frequency
  2. Schedule retraining within <timeframe>
  3. Investigate root causes
<else>
**LOW RISK**: Minimal drift detected, model appears stable
**Recommended Actions**:
  1. Continue routine monitoring
  2. Retrain according to regular schedule
## End If

## Recommendations
RETRAINING WINDOW: <estimated-time-for-retraining>
NEXT: Set up automated drift detection with [ml-train] for retraining
Estimated effort to address: <S/M/L>

## Base120 Context
- Primary: **CO7** (Growth Modeling - monitoring capability degradation)
- Related: **IN16** (Worst case - anticipating failure modes), **SY13** (Designing self-correcting systems)

## After Completion
Naturally chains to: `[ml-train]` for retraining, or implement monitoring automation
