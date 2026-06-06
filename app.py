from flask import Flask, render_template, jsonify
import psycopg2  # type: ignore
import psycopg2.extras  # type: ignore
import os

app = Flask(__name__)

DB_HOST     = os.getenv("DB_HOST", "localhost")
DB_PORT     = os.getenv("DB_PORT", "5432")
DB_NAME     = os.getenv("DB_NAME", "stockdb")
DB_USER     = os.getenv("DB_USER", "stockuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "stockpassword")


def get_conn():
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT,
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD
    )


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/prices")
def prices():
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("""
            SELECT ticker, ts, open, high, low, close, volume
            FROM stock_prices
            ORDER BY ts DESC
            LIMIT 100
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify([dict(r) for r in rows])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/analysis")
def analysis():
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("""
            SELECT ticker, ts, rsi, ma_50, ma_200, macd, signal_line
            FROM stock_analysis
            ORDER BY ts DESC
            LIMIT 100
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify([dict(r) for r in rows])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/summary")
def summary():
    """Latest price + analysis per ticker for dashboard cards."""
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("""
            SELECT DISTINCT ON (p.ticker)
                p.ticker,
                p.close,
                p.open,
                p.high,
                p.low,
                p.volume,
                p.ts,
                a.rsi,
                a.ma_50,
                a.ma_200,
                a.macd,
                a.signal_line
            FROM stock_prices p
            LEFT JOIN stock_analysis a
                ON p.ticker = a.ticker
                AND p.ts = a.ts
            ORDER BY p.ticker, p.ts DESC
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify([dict(r) for r in rows])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/healthz")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
