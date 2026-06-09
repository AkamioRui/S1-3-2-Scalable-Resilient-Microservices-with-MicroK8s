#!/bin/bash
set -e

IMAGE_NAME="web-scrapper"
NETWORK="scrapper-test-net"
DB_CONTAINER="test-db"
SCRAPPER_CONTAINER="test-scrapper"

echo "=============================="
echo " Web-Scrapper Integration Test"
echo "=============================="

cleanup() {
    echo ""
    echo "[cleanup] Removing test containers and network..."
    podman rm -f $DB_CONTAINER $SCRAPPER_CONTAINER 2>/dev/null || true
    podman network rm $NETWORK 2>/dev/null || true
    echo "[cleanup] Done."
}
trap cleanup EXIT

echo "[1/5] Creating test network..."
podman network create $NETWORK

echo "[2/5] Starting test database (MariaDB)..."
podman run -d \
    --name $DB_CONTAINER \
    --network $NETWORK \
    -e MYSQL_DATABASE=stockdb \
    -e MYSQL_USER=stockuser \
    -e MYSQL_PASSWORD=stockdb \
    -e MYSQL_ROOT_PASSWORD=rootpassword \
    docker.io/library/mariadb:11

echo "      Waiting for DB to be ready..."
sleep 12

echo "[3/5] Initializing database schema..."
podman exec $DB_CONTAINER mariadb -u stockuser -pstockdb stockdb -e "
CREATE TABLE IF NOT EXISTS stock_prices (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    ticker      VARCHAR(10)     NOT NULL,
    ts          DATETIME        NOT NULL,
    open        DECIMAL(12,4)   NOT NULL,
    high        DECIMAL(12,4)   NOT NULL,
    low         DECIMAL(12,4)   NOT NULL,
    close       DECIMAL(12,4)   NOT NULL,
    volume      BIGINT          NOT NULL,
    created_at  DATETIME        DEFAULT NOW(),
    UNIQUE KEY uq_ticker_ts (ticker, ts)
);
"

echo "[4/5] Running web-scrapper with dummy data..."
podman run -d \
    --name $SCRAPPER_CONTAINER \
    --network $NETWORK \
    -e DB_HOST=$DB_CONTAINER \
    -e DB_PORT=3306 \
    -e DB_NAME=stockdb \
    -e DB_USER=stockuser \
    -e DB_PASSWORD=stockdb \
    -e TICKERS=AAPL,MSFT \
    -e SCRAPE_INTERVAL=999 \
    -e SCRAPE_PERIOD=5d \
    $IMAGE_NAME

echo "      Inserting dummy data for testing..."
podman exec $DB_CONTAINER mariadb -u stockuser -pstockdb stockdb -e "
INSERT IGNORE INTO stock_prices (ticker,ts,open,high,low,close,volume)
VALUES
('AAPL','2026-06-05 09:00:00',305.50,315.17,303.20,308.10,65270000),
('MSFT','2026-06-05 09:00:00',448.20,455.80,446.10,452.30,22100000);
"

echo "[5/5] Checking rows in stock_prices..."
ROW_COUNT=$(podman exec $DB_CONTAINER mariadb -u stockuser -pstockdb stockdb -se \
    "SELECT COUNT(*) FROM stock_prices;")

echo ""
echo "=============================="
if [ "$ROW_COUNT" -gt "0" ]; then
    echo " PASS  – $ROW_COUNT rows in stock_prices"
    podman exec $DB_CONTAINER mariadb -u stockuser -pstockdb stockdb -e \
        "SELECT ticker, close, ts FROM stock_prices;"
else
    echo " FAIL  – No rows found"
    podman logs $SCRAPPER_CONTAINER
    exit 1
fi
echo "=============================="