#!/usr/bin/env bash
set -euo pipefail

echo "=== analyzer-svc integration test ==="

compose() {
  if command -v podman-compose >/dev/null 2>&1; then
    podman-compose "$@"
  else
    podman compose "$@"
  fi
}

echo
echo "[1] Checking services..."
compose ps

echo
echo "[2] Checking stock_analysis row count..."
compose exec -T database-svc mariadb \
  -u stockuser \
  -pstockdb \
  stockdb \
  -e "SELECT COUNT(*) AS analysis_rows FROM stock_analysis;"

echo
echo "[3] Showing latest analyzer output..."
compose exec -T database-svc mariadb \
  -u stockuser \
  -pstockdb \
  stockdb \
  -e "SELECT ticker, ts, rsi, ma_50, ma_200, macd, signal_line FROM stock_analysis ORDER BY ts DESC LIMIT 5;"

echo
echo "=== Test complete ==="
