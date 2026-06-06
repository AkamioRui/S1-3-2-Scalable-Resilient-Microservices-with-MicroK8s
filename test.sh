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

echo ""
echo "[1/5] Creating test network..."
podman network create $NETWORK

echo "[2/5] Starting test database..."
podman run -d \
    --name $DB_CONTAINER \
    --network $NETWORK \
    -e POSTGRES_DB=stockdb \
    -e POSTGRES_USER=stockuser \
    -e POSTGRES_PASSWORD=stockpassword \
    docker.io/library/postgres:16-alpine

echo "      Waiting for DB to be ready..."
sleep 8

echo "[3/5] Initializing database schema..."
podman exec $DB_CONTAINER psql -U stockuser -d stockdb -c "
CREATE TABLE IF NOT EXISTS stock_prices (
    id          SERIAL PRIMARY KEY,
    ticker      VARCHAR(10)     NOT NULL,
    ts          TIMESTAMP       NOT NULL,
    open        NUMERIC(12, 4)  NOT NULL,
    high        NUMERIC(12, 4)  NOT NULL,
    low         NUMERIC(12, 4)  NOT NULL,
    close       NUMERIC(12, 4)  NOT NULL,
    volume      BIGINT          NOT NULL,
    created_at  TIMESTAMP       DEFAULT NOW(),
    UNIQUE (ticker, ts)
);
"

echo "[4/5] Running web-scrapper image..."
podman run -d \
    --name $SCRAPPER_CONTAINER \
    --network $NETWORK \
    -e DB_HOST=$DB_CONTAINER \
    -e DB_PORT=5432 \
    -e DB_NAME=stockdb \
    -e DB_USER=stockuser \
    -e DB_PASSWORD=stockpassword \
    -e TICKERS=NVDA \
    -e SCRAPE_INTERVAL=999 \
    -e SCRAPE_PERIOD=5d \
    $IMAGE_NAME

echo "      Waiting for scrapper to fetch data (30s)..."
sleep 30

echo "[5/5] Checking rows in stock_prices..."
ROW_COUNT=$(podman exec $DB_CONTAINER psql -U stockuser -d stockdb -t -c \
    "SELECT COUNT(*) FROM stock_prices;")
ROW_COUNT=$(echo $ROW_COUNT | tr -d ' ')

echo ""
echo "=============================="
if [ "$ROW_COUNT" -gt "0" ]; then
    echo " PASS  – $ROW_COUNT rows inserted into stock_prices"
    podman exec $DB_CONTAINER psql -U stockuser -d stockdb -c \
        "SELECT ticker, COUNT(*) as rows FROM stock_prices GROUP BY ticker;"
else
    echo " FAIL  – No rows found in stock_prices"
    echo " Scrapper logs:"
    podman logs $SCRAPPER_CONTAINER
    exit 1
fi
echo "=============================="
