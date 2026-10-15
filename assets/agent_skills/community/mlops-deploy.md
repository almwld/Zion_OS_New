---
name: mlops-deploy
description: Deploy and monitor ML models in production with validation and rollback capabilities. [Maps to CO7.]
version: 0.1.0
execution-mode: side_effecting
argument-hint: <model-path> <environment>
category: backend-infra
status: candidate
---
# ML Ops Deploy Command

Deploy trained machine learning models to production environments with comprehensive validation, monitoring, and rollback capabilities.

## When to Use
- After model evaluation shows production readiness
- Deploying new model versions to staging or production
- When user mentions model deployment requirements
- Implementing blue/green or canary deployment strategies
- Setting up automated model retraining pipelines

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=mlops-deploy] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Validate Deployment Arguments
- Check model path exists and contains valid model artifacts
- Validate environment (staging, production, etc.) is configured
- Ensure required deployment infrastructure is accessible
- Verify monitoring and alerting systems are operational

### 2. Pre-deployment Validation
Run comprehensive checks before deployment:
- Model integrity verification (checksums, signatures)
- Dependency compatibility check
- Resource requirement validation (memory, compute, latency)
- Security scan for model files and dependencies
- Rollback plan verification

### 3. Execute Deployment Strategy
Based on environment and configuration:
- **Blue/Green**: Deploy to new environment, switch traffic after validation
- **Canary**: Gradually route percentage of traffic to new model
- **Rolling Update**: Replace instances incrementally
- **Recreate**: Stop old version, deploy new version (downtime expected)

### 4. Post-deployment Monitoring
Activate monitoring and validation:
- Track key performance indicators (latency, throughput, error rates)
- Monitor data drift and prediction drift
- Validate business impact metrics
- Set up alerts for degradation or anomalies
- Health check endpoints verification

### 5. Enable Rollback Capability
Ensure quick recovery if issues detected:
- Maintain access to previous model version
- Automated rollback triggers based on health metrics
- Manual rollback procedures documented and tested
- Version tracking and audit trail maintenance

## Output Format
```
ML Ops Deploy | <model-path> <environment>
═════════════════════════════
Model: <model-version>
Target Environment: <environment>
Deployment Time: <timestamp>
Strategy: <deployment-strategy>

## Pre-deployment Validation
- Model Integrity: <pass/fail>
- Dependencies: <pass/fail> (<version-mismatches>)
- Resource Requirements: <pass/fail> (<details>)
- Security Scan: <pass/fail> (<vulnerabilities-found>)
- Rollback Plan: <verified/missing>

## Deployment Execution
<if blue-green>
**Blue/Green Deployment**:
  - Green Environment: <environment-id> (new)
  - Blue Environment: <environment-id> (current)
  - Traffic Switch: <time> after validation
  - Validation Criteria: <metrics-thresholds>
<elif canary>
**Canary Deployment**:
  - Initial Traffic: <percentage>% to new model
  - Increase Schedule: <percentage>% every <interval>
  - Full Rollout: <time> or <criteria>
  - Metrics Monitoring: <error-rate, latency, etc>
<elif rolling>
**Rolling Update**:
  - Batch Size: <percentage>% of instances per wave
  - Health Check: <endpoint> between waves
  - Rollback Trigger: <failure-threshold>
<else>
**Recreate Deployment**:
  - Downtime Window: <start> to <end>
  - Pre-stop Hook: <script>
  - Post-start Hook: <script>
## End If

## Post-deployment Status
- Health Endpoints: <status> (<response-times>)
- Traffic Distribution: <old>% old / <new>% new
- Error Rate: <current>% (<baseline>% baseline)
- Latency P95: <value>ms (<baseline>ms baseline)
- Resource Usage: CPU <value>%, Memory <value>%

## Monitoring Alerts
<if alerts-configured>
**Active Alerts**:
  - Data Drift: <status> (<psi-value>)
  - Prediction Drift: <status> (<ks-test-value>)
  - Resource Utilization: <status> (<values>)
  - Business Metrics: <status> (<details>)
<else>
No monitoring alerts configured
## End If

## Rollback Information
- Previous Version: <model-version> available
- Rollback Time: <estimated-time>
- Automatic Triggers: <list-of-conditions>
- Manual Procedure: <documentation-link>

## Recommendations
DEPLOYMENT STATUS: <success/failed/partial>
NEXT STEPS: <monitoring/action-items>
Estimated stabilization time: <time>
Consider [ml-evaluate] for post-deployment validation

## Base120 Context
- Primary: **CO7** (Growth Modeling - deploying improved capabilities)
- Related: **IN2** (Premortem - anticipating deployment failures), **SY13** (Designing reliable systems)

## After Completion
Naturally chains to: Continuous monitoring, or [ml-evaluate] for post-deployment validation

## Skill Chains
- For post-deploy latency and throughput monitoring -> `[stream-inference]` (`python ~/bin/stream_test.py --model <model> --prompt test`)

### Mandatory

- `[deploy-checklist]` MUST pass — pre-deployment validation ensures infrastructure readiness, rollback plan, and monitoring are in place.
- `[ml-evaluate]` MUST pass — model validation confirms the model meets production quality thresholds before deployment.

### Advisory

- After `[mlops-deploy]` → continuous monitoring setup (drift detection, alerting)
- After `[mlops-deploy]` → `[ml-evaluate]` for post-deployment validation
- Before `[mlops-deploy]` → `[ml-train]` if the model needs retraining before deploy

## Authority

- **T1 (TRUSTED)**: May run with all mandatory chains passed
- **T2 (Active/High)**: Operator approval required + all mandatory chains passed
- **T3 (Medium)**: Operator approval required + all mandatory chains passed
- **T4 (Probationary)**: BLOCKED
- **Operator**: Override any restriction
