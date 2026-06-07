# Day 4

## Checklist

- [x] Create `day4-aiops` branch from Day 3.
- [x] Add ServiceMonitor for InsightHub API metrics.
- [x] Add Prometheus recording rules for RED metrics and 3-sigma anomaly bands.
- [x] Add AlertmanagerConfig for Slack routing.
- [x] Add Grafana dashboard with 14 panels.
- [x] Add 3 incident injection scripts.
- [x] Add 3 AI RCA reports with evidence and timestamps.
- [x] Add MLOps overview notes with 4 concept blocks.
- [ ] Apply manifests to a live cluster with kube-prometheus-stack.
- [ ] Configure real Slack webhook as a Kubernetes Secret.

## Verification

```bash
bash scripts/verify-day-4.sh
```

Cluster checks:

```bash
kubectl apply -f observability/servicemonitor.yaml
kubectl apply -f observability/prometheus-rules.yaml
kubectl apply -f observability/alertmanager-config.yaml
kubectl get servicemonitor,prometheusrule,alertmanagerconfig -n insighthub-main
```

## Notes

- Day 4 Prometheus rules use 30m baselines plus lab fallback thresholds.
- The dashboard covers RED, USE, cost signal, and anomaly panels.
- Deploy is expected to happen after kube-prometheus-stack exists in the cluster.

