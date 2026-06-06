# web-api

A lightweight REST API service built with FastAPI that serves stock market data.

## Endpoints

- `GET /health` — returns service status and pod hostname
- `GET /prices?ticker=AAPL` — returns raw stock price data
- `GET /analysis?ticker=AAPL` — returns technical analysis data (RSI, MA50, MA200, MACD)

The `source` field in each response indicates whether data came from `database` or `dummy` (fallback).

## Stack

- Python 3.11
- FastAPI
- Uvicorn
- psycopg2
- Docker image: `localhost:32000/web-api:latest`

## Architecture

This service is part of a microservices stock analysis system deployed on MicroK8s.
It sits behind an NGINX Ingress controller and is accessible via `api.myapp.com`.

Data flow: `web-scrapper → database → analyzer → database → web-api → ingress → user`

## Kubernetes Resources

- **Deployment:** 2 replicas, liveness + readiness probes on `/health`
- **Service:** ClusterIP on port 80
- **Ingress:** Routes `api.myapp.com` to this service
- **HPA:** Auto-scales from 2 to 5 replicas at 50% CPU utilization
- **Resources:** requests 100m CPU / 64Mi RAM, limits 250m CPU / 128Mi RAM

## Database Integration

The API connects to the database service via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| DB_HOST | database-svc | Database service hostname |
| DB_PORT | 5432 | Database port |
| DB_NAME | stockdb | Database name |
| DB_USER | stockuser | Database user |
| DB_PASSWORD | stockpassword | Database password |

If the database is unavailable, the API automatically falls back to dummy data.

## Building the image

```bash
podman build -t localhost:32000/web-api:latest .
podman push --tls-verify=false localhost:32000/web-api:latest
```