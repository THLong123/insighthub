# Day 4 MLOps Overview Notes

## 1. Mindset

Application artifacts and model artifacts are different.

- App artifact: deterministic code package, usually versioned by commit SHA.
- Model artifact: learned behavior, versioned by training data, code, feature schema, metrics, and approval state.
- App regressions usually come from code or config changes.
- Model regressions can come from code, data drift, concept drift, or serving skew.

The DevOps responsibility is to build the reliable path around the model. DevOps does not silently retrain or promote models without ML owner approval.

## 2. Lifecycle

The ML lifecycle has more stages than a normal app delivery path:

1. Data collection and validation.
2. Feature engineering.
3. Training and experiment tracking.
4. Evaluation and model registration.
5. Staging deployment.
6. A/B or shadow rollout.
7. Production serving.
8. Monitoring, drift detection, rollback, and retraining request.

DevOps owns the platform and gates for stages 4-8: registry, CI/CD, secrets, runtime, observability, rollback, and audit trail.

## 3. Registry And Approval Gate

A model registry is the source of truth for model artifact metadata:

- model name and version
- training dataset version
- evaluation metrics
- owner and reviewer
- approval state
- serving image or package reference

Promotion pattern:

1. Candidate model enters Staging.
2. Automated checks validate schema, metrics, and security.
3. Human owner approves promotion.
4. Traffic shifts gradually through shadow, canary, or A/B.
5. Production promotion is recorded with rollback metadata.

Approval matters because technically deployable is not the same as business-safe.

## 4. Drift, Rollback, And Ownership

Data drift means production input distribution changes. Concept drift means the relationship between input and correct output changes.

Operational signals:

- input schema failures
- feature null-rate changes
- prediction confidence shift
- latency and error-rate change
- cost per prediction increase

Ownership boundary:

| Area | DevOps Owns | ML Team Owns |
|---|---|---|
| Serving runtime | Kubernetes, scaling, alerts | model server contract |
| Registry | platform and permissions | model metadata quality |
| Approval gate | workflow enforcement | accept or reject promotion |
| Drift alert | detection pipeline | investigation and retraining decision |
| Rollback | safe rollback mechanism | choose known-good model |

Key rule: DevOps can rollback serving to a known-good approved model. DevOps should not auto-retrain a new model without ML team ownership.

