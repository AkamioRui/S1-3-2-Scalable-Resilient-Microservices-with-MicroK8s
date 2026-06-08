# This branch contains all necessary file to build an image

# database-svc

This branch contains all necessary files to build an image for the database service.

This includes a Dockerfile.

## Files

| File           | Description                                       |
| -------------- | ------------------------------------------------- |
| `Dockerfile`   | Builds the MariaDB image with default credentials |
| `init.sql`     | Initializes the database schema on first startup  |
| `.env.example` | Example environment variables for local testing   |

## Tables

| Table            | Description                             |
| ---------------- | --------------------------------------- |
| `stock_prices`   | Raw OHLCV data                          |
| `stock_analysis` | Computed RSI, MA50, MA200, MACD results |

## How to Build and Push

```bash
docker build -t localhost:32000/database:latest .

docker push localhost:32000/database:latest
```

---

## How to Test

### 1. Start the service

```bash
docker compose up --build database-svc
```

### 2. Verify the container is running

```bash
docker ps
```

Expected: `database-svc` with status `Up`.

### 3. Connect to the database

```bash
mysql -h 127.0.0.1 -u stockuser -p stockdb
# password: stockpassword
```
