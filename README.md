# Analyzer service

The analyzer reads raw OHLCV rows from `stock_prices`, calculates technical
indicators, and writes the result to `stock_analysis` for the web API/server.

## Indicators

| Column | Calculation |
| --- | --- |
| `rsi` | 14-period RSI |
| `ma_50` | 50-period simple moving average |
| `ma_200` | 200-period simple moving average |
| `macd` | EMA 12 minus EMA 26 |
| `signal_line` | 9-period EMA of MACD |

When there is not enough price history for an indicator, the analyzer stores
`NULL` for that column.

## Environment variables

| Name | Default | Description |
| --- | --- | --- |
| `DB_HOST` | `database-svc` | MariaDB host |
| `DB_PORT` | `3306` | MariaDB port |
| `DB_NAME` | `stockdb` | Database name |
| `DB_USER` | `stockuser` | Database user |
| `DB_PASSWORD` | `stockdb` | Database password |
| `ANALYZE_INTERVAL` | `60` | Seconds between analyzer cycles |
| `PRICE_LIMIT` | `300` | Latest raw rows loaded per ticker |
| `TICKERS` | empty | Optional comma-separated ticker allowlist |

## Build

```bash
docker build -t localhost:32000/analyzer:latest .
docker push localhost:32000/analyzer:latest
```

## Kubernetes

```bash
kubectl apply -f k8s_manifest/analyzer-deploy.yaml
```

## Local integration test

This branch includes a `podman-compose.yml` that expects the standard cloned
folder layout from the main branch:

```text
images/
  analyzer/
  database/
  web-scrapper/
```

From `images/analyzer`, run:

```bash
podman compose up --build
```

The compose file starts `database-svc`, `web-scrapper-svc`, and `analyzer-svc`.
After the scraper inserts rows into `stock_prices`, the analyzer should write
indicator rows into `stock_analysis`.
