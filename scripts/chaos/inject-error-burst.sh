#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:-http://localhost:8000}"
DURATION_SECONDS="${2:-180}"

echo "Injecting error burst for ${DURATION_SECONDS}s against ${API_URL}"
echo "Requests intentionally hit a missing endpoint to create 404 traffic."

end_at=$((SECONDS + DURATION_SECONDS))
while [ "$SECONDS" -lt "$end_at" ]; do
  curl -sS -o /dev/null -w "%{http_code}\n" "${API_URL}/__day4_missing_endpoint__" || true
  sleep 1
done

echo "Error burst finished."

