import os
from fastapi import FastAPI

app = FastAPI()

# Dummy stock prices data
DUMMY_PRICES = {
    "AAPL": [
        {"ts": "2024-01-01T00:00:00", "open": 185.2, "high": 187.3, "low": 184.1, "close": 186.5, "volume": 52000000},
        {"ts": "2024-01-02T00:00:00", "open": 186.5, "high": 188.0, "low": 185.0, "close": 187.2, "volume": 48000000},
    ]
}

# Dummy analysis data
DUMMY_ANALYSIS = {
    "AAPL": [
        {"ts": "2024-01-01T00:00:00", "rsi": 55.3, "ma_50": 182.4, "ma_200": 175.2, "macd": 1.2, "signal_line": 0.9},
        {"ts": "2024-01-02T00:00:00", "rsi": 57.1, "ma_50": 182.8, "ma_200": 175.4, "macd": 1.4, "signal_line": 1.0},
    ]
}

@app.get("/health")
def health():
    return {"status": "ok", "pod": os.environ.get("HOSTNAME", "unknown")}

@app.get("/prices")
def get_prices(ticker: str = "AAPL"):
    data = DUMMY_PRICES.get(ticker.upper())
    if not data:
        return {"error": f"No data for ticker {ticker}"}
    return {"ticker": ticker.upper(), "prices": data}

@app.get("/analysis")
def get_analysis(ticker: str = "AAPL"):
    data = DUMMY_ANALYSIS.get(ticker.upper())
    if not data:
        return {"error": f"No data for ticker {ticker}"}
    return {"ticker": ticker.upper(), "analysis": data}