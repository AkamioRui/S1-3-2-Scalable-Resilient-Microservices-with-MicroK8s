# web-api

A lightweight REST API service built with FastAPI that serves stock market data.

## Endpoints

- `GET /health` — returns service status and pod hostname
- `GET /prices?ticker=AAPL` — returns raw stock price data
- `GET /analysis?ticker=AAPL` — returns technical analysis data (RSI, MA50, MA200, MACD)

## Stack

- Python 3.11
- FastAPI
- Uvicorn
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

## Building the image

```bash
podman build -t localhost:32000/web-api:latest .
podman push --tls-verify=false localhost:32000/web-api:latest
```