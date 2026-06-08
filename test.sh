#!/bin/bash

HOST="127.0.0.1"
PORT="3306"
USER="stockuser"
PASSWORD="stockpassword"
DB="stockdb"

echo "=== database-svc image test ==="

echo ""
echo "[1] Checking container status..."
if docker ps | grep -q "database-svc"; then
    echo "    Container is running"
else
    echo "    Container is not running"
    exit 1
fi

echo ""
echo "[2] Checking port $PORT..."
if nc -z $HOST $PORT 2>/dev/null; then
    echo "    Port $PORT is open"
else
    echo "    Port $PORT is not reachable"
    exit 1
fi

# 3. Check if tables exist
echo ""
echo "[3] Checking tables..."
TABLES=$(mysql -h $HOST -u $USER -p$PASSWORD $DB -e "SHOW TABLES;" 2>/dev/null)

if echo "$TABLES" | grep -q "stock_prices"; then
    echo "    Table stock_prices exists"
else
    echo "    Table stock_prices not found"
fi

if echo "$TABLES" | grep -q "stock_analysis"; then
    echo "    Table stock_analysis exists"
else
    echo "    Table stock_analysis not found"
fi

echo ""
echo "=== Test complete ==="