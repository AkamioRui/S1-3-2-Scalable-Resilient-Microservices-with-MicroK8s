import os
import psycopg2
import psycopg2.extras
from fastapi import FastAPI

app = FastAPI()

# Database connection config
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "database-svc"),
    "port": int(os.environ.get("DB_PORT", 5432)),
    "dbname": os.environ.get("DB_NAME", "stockdb"),
    "user": os.environ.get("DB_USER", "stockuser"),
    "password": os.environ.get("DB_PASSWORD", "stockpassword"),
}

# Dummy fallback data
DUMMY_PRICES = {
    "AAPL": [
        {"ts": "2024-01-01T00:00:00", "open": 185.2, "high": 187.3, "low": 184.1, "close": 186.5, "volume": 52000000},
        {"ts": "2024-01-02T00:00:00", "open": 186.5, "high": 188.0, "low": 185.0, "close": 187.2, "volume": 48000000},
    ]
}

DUMMY_ANALYSIS = {
    "AAPL": [
        {"ts": "2024-01-01T00:00:00", "rsi": 55.3, "ma_50": 182.4, "ma_200": 175.2, "macd": 1.2, "signal_line": 0.9},
        {"ts": "2024-01-02T00:00:00", "rsi": 57.1, "ma_50": 182.8, "ma_200": 175.4, "macd": 1.4, "signal_line": 1.0},
    ]
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.get("/health")
def health():
    return {"status": "ok", "pod": os.environ.get("HOSTNAME", "unknown")}

@app.get("/prices")
def get_prices(ticker: str = "AAPL"):
    try:
        conn = get_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            "SELECT ts, open, high, low, close, volume FROM stock_prices WHERE ticker = %s ORDER BY ts DESC LIMIT 50",
            (ticker.upper(),)
        )
        rows = cur.fetchall()
        cur.close()
        conn.close()

        if not rows:
            return {"ticker": ticker.upper(), "source": "dummy", "prices": DUMMY_PRICES.get(ticker.upper(), [])}

        return {"ticker": ticker.upper(), "source": "database", "prices": [dict(r) for r in rows]}

    except Exception as e:
        return {"ticker": ticker.upper(), "source": "dummy", "prices": DUMMY_PRICES.get(ticker.upper(), []), "error": str(e)}

@app.get("/analysis")
def get_analysis(ticker: str = "AAPL"):
    try:
        conn = get_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            "SELECT ts, rsi, ma_50, ma_200, macd, signal_line FROM stock_analysis WHERE ticker = %s ORDER BY ts DESC LIMIT 50",
            (ticker.upper(),)
        )
        rows = cur.fetchall()
        cur.close()
        conn.close()

        if not rows:
            return {"ticker": ticker.upper(), "source": "dummy", "analysis": DUMMY_ANALYSIS.get(ticker.upper(), [])}

        return {"ticker": ticker.upper(), "source": "database", "analysis": [dict(r) for r in rows]}

    except Exception as e:
        return {"ticker": ticker.upper(), "source": "dummy", "analysis": DUMMY_ANALYSIS.get(ticker.upper(), []), "error": str(e)}