{{ config(materialized='view') }}

WITH raw_source AS (
    SELECT 
        METADATA$FILENAME AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp,
        $1 AS json_payload
    FROM @financial_lakehouse.bronze.s3_raw_stage
)

SELECT
    source_file_name,
    ingestion_timestamp,
    json_payload:AAPL[0]:c::FLOAT AS apple_close_price,
    json_payload:MSFT[0]:c::FLOAT AS msft_close_price,
    json_payload:NVDA[0]:c::FLOAT AS nvda_close_price
FROM raw_source