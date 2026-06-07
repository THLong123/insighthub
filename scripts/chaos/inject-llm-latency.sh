#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:-http://localhost:8000}"
DURATION_SECONDS="${2:-300}"
QUESTION="${3:-Explain the InsightHub ingestion pipeline in one sentence.}"

echo "Injecting LLM latency load for ${DURATION_SECONDS}s against ${API_URL}"
echo "This script creates repeated chat requests so LLM latency histograms move."
echo "Stop early with Ctrl+C."

end_at=$((SECONDS + DURATION_SECONDS))
while [ "$SECONDS" -lt "$end_at" ]; do
  curl -sS -X POST "${API_URL}/chat" \
    -H "Content-Type: application/json" \
    -d "{\"question\":\"${QUESTION}\",\"top_k\":3}" >/dev/null || true
  sleep 2
done

echo "LLM latency load finished."

