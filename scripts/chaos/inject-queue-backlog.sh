#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-insighthub-main}"
DEPLOYMENT="${2:-api}"
DEPTH="${3:-100}"

echo "Setting insighthub_ingestion_queue_depth=${DEPTH} in ${NAMESPACE}/${DEPLOYMENT}"
kubectl exec "deployment/${DEPLOYMENT}" -n "${NAMESPACE}" -- \
  python3 -c "from app.core.metrics import ingestion_queue_depth; ingestion_queue_depth.set(${DEPTH}); print('queue_depth=${DEPTH}')"

echo "Queue backlog metric injected. Wait for Prometheus scrape + alert evaluation."

