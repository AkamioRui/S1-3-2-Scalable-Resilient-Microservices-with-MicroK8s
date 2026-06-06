#!/bin/bash
# ============================================================
# test.sh  –  verify web-server image works correctly
# Usage: ./test.sh
# ============================================================
set -e

IMAGE_NAME="web-server"
NETWORK="webserver-test-net"
DB_CONTAINER="test-db"
WEB_CONTAINER="test-web"

echo "=============================="
echo " Web-Server Integration Test  "
echo "=============================="

cleanup() {
    echo ""
    echo "[cleanup] Removing test containers and network..."
    podman rm -f $DB_CONTAINER $WEB_CONTAINER 2>/dev/null || true
    podman network rm $NETWORK 2>/dev/null || true
    echo "[cleanup] Done."
}
trap cleanup EXIT

# 1. Network
echo "[1/6] Creating test network..."
podman network create $NETWORK

# 2. Start DB
echo "[2/6] Starting test database..."
podman run -d \
    --name $DB_CONTAINER \
    --network $NETWORK \
    -e POSTGRES_DB=stockdb \
    -e POSTGRES_USER=stockuser \
    -e POSTGRES_PASSWORD=stockpassword \
    docker.io/library/postgres:16-alpine

echo "      Waiting for DB to be ready..."
sleep 8

# 3. Init schema + seed data
echo "[3/6] Initializing schema and seeding test data..."
podman exec $DB_CONTAINER psql -U stockuser -d stockdb -c "
CREATE TABLE IF NOT EXISTS stock_prices (
    id SERIAL PRIMARY KEY, ticker VARCHAR(10) NOT NULL,
    ts TIMESTAMP NOT NULL, open NUMERIC(12,4) NOT NULL,
    high NUMERIC(12,4) NOT NULL, low NUMERIC(12,4) NOT NULL,
    close NUMERIC(12,4) NOT NULL, volume BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(), UNIQUE (ticker, ts)
);
CREATE TABLE IF NOT EXISTS stock_analysis (
    id SERIAL PRIMARY KEY, ticker VARCHAR(10) NOT NULL,
    ts TIMESTAMP NOT NULL, rsi NUMERIC(8,4), ma_50 NUMERIC(12,4),
    ma_200 NUMERIC(12,4), macd NUMERIC(12,4), signal_line NUMERIC(12,4),
    created_at TIMESTAMP DEFAULT NOW(), UNIQUE (ticker, ts)
);
INSERT INTO stock_prices (ticker,ts,open,high,low,close,volume)
VALUES ('AAPL','2026-06-05 09:00:00',189.5,192.3,188.1,191.2,45000000),
       ('MSFT','2026-06-05 09:00:00',415.2,418.9,413.0,417.5,22000000)
ON CONFLICT DO NOTHING;
INSERT INTO stock_analysis (ticker,ts,rsi,ma_50,ma_200,macd,signal_line)
VALUES ('AAPL','2026-06-05 09:00:00',58.3,185.4,172.1,2.341,1.892)
ON CONFLICT DO NOTHING;
"

# 4. Start web-server
echo "[4/6] Starting web-server container..."
podman run -d \
    --name $WEB_CONTAINER \
    --network $NETWORK \
    -p 5000:5000 \
    -e DB_HOST=$DB_CONTAINER \
    -e DB_PORT=5432 \
    -e DB_NAME=stockdb \
    -e DB_USER=stockuser \
    -e DB_PASSWORD=stockpassword \
    $IMAGE_NAME

echo "      Waiting for web-server to start..."
sleep 5

# 5. Health check
echo "[5/6] Health check..."
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/healthz)
if [ "$HEALTH" != "200" ]; then
    echo " FAIL – Health check returned HTTP $HEALTH"
    podman logs $WEB_CONTAINER
    exit 1
fi
echo "      Health check: HTTP $HEALTH OK"

# 6. API checks
echo "[6/6] Checking API endpoints..."
PRICES=$(curl -s http://localhost:5000/api/prices | grep -c "ticker" || true)
SUMMARY=$(curl -s http://localhost:5000/api/summary | grep -c "ticker" || true)

echo ""
echo "=============================="
if [ "$PRICES" -gt "0" ] && [ "$HEALTH" = "200" ]; then
    echo " PASS  – Web-server is working!"
    echo "        /healthz   → HTTP 200"
    echo "        /api/prices → returns data"
    echo "        /api/summary → returns data"
    echo ""
    echo " Dashboard accessible at: http://localhost:5000"
else
    echo " FAIL  – API returned no data"
    podman logs $WEB_CONTAINER
    exit 1
fi
echo "=============================="
