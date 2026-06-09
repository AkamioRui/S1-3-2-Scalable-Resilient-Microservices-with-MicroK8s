import yfinance as yf
import pymysql  # type: ignore
import pandas as pd
import time
import os
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

DB_HOST     = os.getenv("DB_HOST", "localhost")
DB_PORT     = int(os.getenv("DB_PORT", "3306"))
DB_NAME     = os.getenv("DB_NAME", "stockdb")
DB_USER     = os.getenv("DB_USER", "stockuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "stockdb")

TICKERS  = os.getenv("TICKERS", "AAPL,MSFT,GOOGL,TSLA,AMZN").split(",")
INTERVAL = int(os.getenv("SCRAPE_INTERVAL", "60"))
PERIOD   = os.getenv("SCRAPE_PERIOD", "7d")


def get_connection():
    return pymysql.connect(
        host=DB_HOST, port=DB_PORT,
        db=DB_NAME, user=DB_USER, password=DB_PASSWORD,
        cursorclass=pymysql.cursors.DictCursor
    )


def fetch_and_insert(conn, ticker: str):
    log.info(f"Fetching {ticker} ...")
    raw = yf.download(ticker, period=PERIOD, interval="1h", auto_adjust=True, progress=False)
    df: pd.DataFrame = raw  # type: ignore[assignment]

    if df.empty:  # type: ignore[union-attr]
        log.warning(f"No data returned for {ticker}")
        return 0

    rows_inserted = 0
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = df.columns.get_level_values(0)

    with conn.cursor() as cur:
        for ts, row in df.iterrows():  # type: ignore[union-attr]
            try:
                ts_dt = pd.Timestamp(ts).to_pydatetime()
                cur.execute(
                    """
                    INSERT IGNORE INTO stock_prices (ticker, ts, open, high, low, close, volume)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        ticker,
                        ts_dt,
                        float(row["Open"]),
                        float(row["High"]),
                        float(row["Low"]),
                        float(row["Close"]),
                        int(row["Volume"]),
                    ),
                )
                rows_inserted += cur.rowcount
            except Exception as e:
                log.error(f"Row insert error for {ticker} at {ts}: {e}")
                conn.rollback()
                return rows_inserted
    conn.commit()
    log.info(f"{ticker}: {rows_inserted} new rows inserted")
    return rows_inserted


def wait_for_db(retries=10, delay=5):
    for attempt in range(1, retries + 1):
        try:
            conn = get_connection()
            conn.close()
            log.info("Database is ready!")
            return
        except Exception as e:
            log.warning(f"DB not ready (attempt {attempt}/{retries}): {e}")
            time.sleep(delay)
    raise RuntimeError("Could not connect to database after multiple retries")


def main():
    log.info("Web-scrapper starting...")
    log.info(f"Tickers : {TICKERS}")
    log.info(f"Interval: {INTERVAL}s | Period: {PERIOD}")

    wait_for_db()

    while True:
        try:
            conn = get_connection()
            for ticker in TICKERS:
                fetch_and_insert(conn, ticker.strip())
            conn.close()
        except Exception as e:
            log.error(f"Unexpected error: {e}")
        log.info(f"Sleeping {INTERVAL}s before next fetch...")
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()