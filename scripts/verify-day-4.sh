#!/usr/bin/env bash
# InsightHub - Verify Day 4 (AIOps + MLOps Overview)
set -u

PASS=0
FAIL=0

green(){ printf "\033[32m%s\033[0m\n" "$1"; }
red(){ printf "\033[31m%s\033[0m\n" "$1"; }
ok(){ green "  [PASS] $1"; PASS=$((PASS+1)); }
ng(){ red "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== InsightHub - Verify Day 4 (AIOps) ==="

# ServiceMonitor
if [ -f observability/servicemonitor.yaml ] || [ -f observability/service-monitor.yaml ]; then
  ok "ServiceMonitor manifest exists"
else
  ng "ServiceMonitor manifest is missing"
fi

# Anomaly rules
if [ -f observability/anomaly-rules.yaml ] || [ -f observability/prometheus-rules.yaml ]; then
  RULES=$(cat observability/anomaly-rules.yaml observability/prometheus-rules.yaml 2>/dev/null)
  if echo "$RULES" | grep -qE "_anomaly|_upper_band|_baseline"; then
    ok "Anomaly band recording rules detected"
  else
    ng "Anomaly band recording rules are missing"
  fi

  RULE_FILE=""
  [ -f observability/promtool-rules.yaml ] && RULE_FILE="observability/promtool-rules.yaml"
  [ -z "$RULE_FILE" ] && [ -f observability/prometheus-rules.yaml ] && RULE_FILE="observability/prometheus-rules.yaml"
  [ -z "$RULE_FILE" ] && [ -f observability/anomaly-rules.yaml ] && RULE_FILE="observability/anomaly-rules.yaml"

  if [ -n "$RULE_FILE" ] && command -v promtool >/dev/null; then
    promtool check rules "$RULE_FILE" 2>&1 | grep -q "SUCCESS" \
      && ok "promtool check rules SUCCESS" || ng "promtool reported an error"
  fi
else
  ng "Anomaly rules YAML is missing"
fi

# Grafana dashboard JSON
if [ -d observability/grafana-dashboards ] && ls observability/grafana-dashboards/*.json >/dev/null 2>&1; then
  PANELS=$(jq -r '.panels | length' observability/grafana-dashboards/*.json 2>/dev/null | head -1)
  if [ -n "$PANELS" ] && [ "$PANELS" -ge 9 ]; then
    ok "Grafana dashboard has $PANELS panels"
  else
    ng "Grafana dashboard has $PANELS panels, expected at least 9"
  fi
else
  ng "Grafana dashboard JSON is missing"
fi

# RCA reports
RCA_COUNT=$(ls rca-reports/incident-*.json 2>/dev/null | wc -l)
if [ "$RCA_COUNT" -ge 3 ]; then
  ok "RCA reports: $RCA_COUNT"
  for f in rca-reports/incident-*.json; do
    if jq -e '.top_hypotheses[0].evidence' "$f" >/dev/null 2>&1; then
      ok "$(basename "$f") has cited evidence"
    else
      ng "$(basename "$f") is missing hypothesis evidence"
    fi
  done
else
  ng "RCA reports: $RCA_COUNT, expected at least 3"
fi

# MLOps overview notes
if [ -f mlops-overview-notes.md ] || [ -f docs/mlops-overview-notes.md ]; then
  NOTE=$(cat mlops-overview-notes.md docs/mlops-overview-notes.md 2>/dev/null)
  COUNT=$(echo "$NOTE" | grep -cE "Mindset|Lifecycle|Registry|Approval|Drift|Rollback|Ownership")
  if [ "$COUNT" -ge 4 ]; then
    ok "MLOps overview notes include the required concepts"
  else
    ng "MLOps overview notes are missing required concepts"
  fi
else
  ng "mlops-overview-notes.md is missing"
fi

echo
echo "=== Result: $PASS PASS / $FAIL FAIL ==="
[ "$FAIL" -eq 0 ] && green "Day 4 OK" || { red "Review Day 4 requirements"; exit 1; }
