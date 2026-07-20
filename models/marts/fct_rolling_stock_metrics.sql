{{ config(materialized='table') }}

WITH staging_data AS (
    SELECT
        source_file_name,
        -- Extract a clean date string from our metadata filename
        TRY_CAST(SPLIT_PART(SPLIT_PART(source_file_name, 'market_data_', 2), '.json', 1) AS DATE) AS trading_date,
        ingestion_timestamp,
        apple_close_price,
        msft_close_price,
        nvda_close_price
    FROM {{ ref('stg_alpaca_market_data') }}
)

SELECT
    trading_date,
    ingestion_timestamp,
    source_file_name,
    
    -- Active Stock Close Prices
    apple_close_price,
    msft_close_price,
    nvda_close_price,

    -- Multi-Day Rolling Averages (Window Functions)
    AVG(apple_close_price) OVER (
        ORDER BY trading_date 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS apple_rolling_5_day_avg,

    AVG(msft_close_price) OVER (
        ORDER BY trading_date 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS msft_rolling_5_day_avg,

    AVG(nvda_close_price) OVER (
        ORDER BY trading_date 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS nvda_rolling_5_day_avg

FROM staging_data
ORDER BY trading_date DESC