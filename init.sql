
-- Raw stock price data
CREATE TABLE IF NOT EXISTS stock_prices (
    id          SERIAL PRIMARY KEY,
    ticker      VARCHAR(10)     NOT NULL,   -- stock symbol
    ts          TIMESTAMP       NOT NULL,   -- timestamp of the price
    open        NUMERIC(12, 4)  NOT NULL,   -- candlestick value
    high        NUMERIC(12, 4)  NOT NULL,   -- ^
    low         NUMERIC(12, 4)  NOT NULL,   -- ^
    close       NUMERIC(12, 4)  NOT NULL,   -- ^
    volume      BIGINT          NOT NULL,   -- shares traded
    created_at  TIMESTAMP       DEFAULT NOW(),
    UNIQUE (ticker, ts)     -- duplicate prevention
);

-- Analysis results produced by the analyzer
CREATE TABLE IF NOT EXISTS stock_analysis (
    id          SERIAL PRIMARY KEY,
    ticker      VARCHAR(10)     NOT NULL,
    ts          TIMESTAMP       NOT NULL,  -- timestamp this analysis refers to
    rsi         NUMERIC(8, 4),      -- result from the analyzer
    ma_50       NUMERIC(12, 4),     -- ^
    ma_200      NUMERIC(12, 4),     -- ^
    macd        NUMERIC(12, 4),     -- ^
    signal_line NUMERIC(12, 4),     -- ^
    created_at  TIMESTAMP       DEFAULT NOW(),
    UNIQUE (ticker, ts)
);

-- speed up indexes lookups by ticker and time
CREATE INDEX IF NOT EXISTS idx_prices_ticker_ts     ON stock_prices     (ticker, ts DESC);
CREATE INDEX IF NOT EXISTS idx_analysis_ticker_ts   ON stock_analysis   (ticker, ts DESC);