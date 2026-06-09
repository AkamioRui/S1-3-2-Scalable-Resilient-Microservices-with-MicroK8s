import logging
import os
import time
from typing import Optional

import pandas as pd
import pymysql
import pymysql.cursors

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

DB_HOST = os.getenv("DB_HOST", "database-svc")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_NAME = os.getenv("DB_NAME", "stockdb")
DB_USER = os.getenv("DB_USER", "stockuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "stockdb")

ANALYZE_INTERVAL = int(os.getenv("ANALYZE_INTERVAL", "60"))
PRICE_LIMIT = int(os.getenv("PRICE_LIMIT", "300"))
TICKERS = [ticker.strip().upper() for ticker in os.getenv("TICKERS", "").split(",") if ticker.strip()]
HEARTBEAT_FILE = os.getenv("HEARTBEAT_FILE", "/tmp/analyzer-heartbeat")


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        db=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        cursorclass=pymysql.cursors.DictCursor,
    )


def wait_for_db(retries: int = 20, delay: int = 5):
    for attempt in range(1, retries + 1):
        try:
            conn = get_connection()
            conn.close()
            log.info("Database is ready")
            return
        except Exception as exc:
            log.warning("DB not ready (attempt %s/%s): %s", attempt, retries, exc)
            time.sleep(delay)
    raise RuntimeError("Could not connect to database after multiple retries")


def get_tickers(conn) -> list[str]:
    if TICKERS:
        return TICKERS

    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT ticker FROM stock_prices ORDER BY ticker")
        return [row["ticker"] for row in cur.fetchall()]


def load_prices(conn, ticker: str) -> pd.DataFrame:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT ticker, ts, close
            FROM stock_prices
            WHERE ticker = %s
            ORDER BY ts DESC
            LIMIT %s
            """,
            (ticker, PRICE_LIMIT),
        )
        rows = cur.fetchall()

    if not rows:
        return pd.DataFrame(columns=["ticker", "ts", "close"])

    df = pd.DataFrame(rows)
    df["close"] = pd.to_numeric(df["close"], errors="coerce")
    return df.dropna(subset=["close"]).sort_values("ts").reset_index(drop=True)


def optional_float(value) -> Optional[float]:
    if pd.isna(value):
        return None
    return float(value)


def calculate_indicators(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df

    close = df["close"]

    delta = close.diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.rolling(window=14, min_periods=14).mean()
    avg_loss = loss.rolling(window=14, min_periods=14).mean()
    rs = avg_gain / avg_loss.mask(avg_loss == 0)

    df["rsi"] = 100 - (100 / (1 + rs))
    df.loc[(avg_loss == 0) & (avg_gain > 0), "rsi"] = 100
    df.loc[(avg_loss == 0) & (avg_gain == 0), "rsi"] = 50

    df["ma_50"] = close.rolling(window=50, min_periods=50).mean()
    df["ma_200"] = close.rolling(window=200, min_periods=200).mean()

    ema_12 = close.ewm(span=12, adjust=False, min_periods=12).mean()
    ema_26 = close.ewm(span=26, adjust=False, min_periods=26).mean()
    df["macd"] = ema_12 - ema_26
    df["signal_line"] = df["macd"].ewm(span=9, adjust=False, min_periods=9).mean()

    return df


def upsert_analysis(conn, ticker: str, df: pd.DataFrame) -> int:
    if df.empty:
        return 0

    rows = [
        (
            ticker,
            row.ts.to_pydatetime() if hasattr(row.ts, "to_pydatetime") else row.ts,
            optional_float(row.rsi),
            optional_float(row.ma_50),
            optional_float(row.ma_200),
            optional_float(row.macd),
            optional_float(row.signal_line),
        )
        for row in df.itertuples(index=False)
    ]

    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO stock_analysis (ticker, ts, rsi, ma_50, ma_200, macd, signal_line)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                rsi = VALUES(rsi),
                ma_50 = VALUES(ma_50),
                ma_200 = VALUES(ma_200),
                macd = VALUES(macd),
                signal_line = VALUES(signal_line),
                created_at = NOW()
            """,
            rows,
        )
    conn.commit()
    return len(rows)


def write_heartbeat():
    with open(HEARTBEAT_FILE, "w", encoding="utf-8") as heartbeat:
        heartbeat.write(str(int(time.time())))


def analyze_once() -> int:
    conn = get_connection()
    total_rows = 0
    try:
        tickers = get_tickers(conn)
        if not tickers:
            log.info("No tickers found in stock_prices")
            return 0

        for ticker in tickers:
            prices = load_prices(conn, ticker)
            analyzed = calculate_indicators(prices)
            row_count = upsert_analysis(conn, ticker, analyzed)
            total_rows += row_count
            log.info("%s: analyzed %s rows", ticker, row_count)
        return total_rows
    finally:
        conn.close()


def main():
    log.info("Analyzer starting")
    log.info("Interval: %ss | Price limit per ticker: %s", ANALYZE_INTERVAL, PRICE_LIMIT)
    wait_for_db()

    while True:
        try:
            rows = analyze_once()
            write_heartbeat()
            log.info("Analyzer cycle complete, %s rows upserted", rows)
        except Exception as exc:
            log.exception("Analyzer cycle failed: %s", exc)
        time.sleep(ANALYZE_INTERVAL)


if __name__ == "__main__":
    main()
