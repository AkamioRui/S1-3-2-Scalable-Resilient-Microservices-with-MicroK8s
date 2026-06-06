# web-scrapper

Fetches stock price data from **yfinance** and inserts it into the PostgreSQL database (`stock_prices` table).

## Environment Variables

| Variable          | Default       | Description                        |
|-------------------|---------------|------------------------------------|
| `DB_HOST`         | `localhost`   | PostgreSQL host                    |
| `DB_PORT`         | `5432`        | PostgreSQL port                    |
| `DB_NAME`         | `stockdb`     | Database name                      |
| `DB_USER`         | `stockuser`   | Database user                      |
| `DB_PASSWORD`     | `stockpassword` | Database password                |
| `TICKERS`         | `AAPL,MSFT,GOOGL,TSLA,AMZN` | Comma-separated stock tickers |
| `SCRAPE_INTERVAL` | `60`          | Seconds between each fetch cycle   |
| `SCRAPE_PERIOD`   | `7d`          | How far back to fetch (yfinance period) |

## Build

```bash
podman build -t web-scrapper .
```

## Test

```bash
chmod +x test.sh
./test.sh
```

## Data inserted

Inserts into `stock_prices` table:
```
ticker | ts | open | high | low | close | volume
```
Duplicate rows (same ticker + timestamp) are silently ignored via `ON CONFLICT DO NOTHING`.