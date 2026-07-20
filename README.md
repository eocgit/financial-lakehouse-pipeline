# financial-lakehouse-pipeline
# Cloud Financial Data Pipeline & Real-Time News Sentiment Enrichment

A personal data engineering project demonstrating automated ingestion, transformation, and AI enrichment of structured financial market data and unstructured news text. Built using cloud-native tooling, a keyless security integration between AWS and Snowflake, and dbt-based data modeling.

## System Architecture

### 1. Batch Financial Processing Lane (Quantitative Data)
*   **Source:** Alpaca Market Data API
*   **Ingestion:** n8n Workflow (Scheduled Batch Daily at 14:15 MST)
*   **Storage (Bronze):** Amazon Web Services (AWS) S3 Data Lake
*   **Staging (Silver):** Snowflake External Stages ➔ dbt Cloud Transformation Views
*   **Analytics (Gold):** dbt Materialized Tables (SQL Window Functions)

### 2. Stream AI Processing Lane (Qualitative Text Data)
*   **Source:** CNBC Live Global Market RSS Feed
*   **Ingestion:** n8n Workflow (Real-Time Event Stream Trigger)
*   **AI Enrichment:** Google Gemini 2.5 Flash Model Endpoint (Structured JSON Parsing)
*   **Storage:** Snowflake Real-Time Insertion Table

## Implementation Details

### 1. Automated Multi-Source Ingestion
*   **Orchestration:** Deployed an automated workflow runner on a self-hosted Oracle Cloud Infrastructure (OCI) Compute Instance running Linux.
*   **Batch Ingestion:** Built `prod_ingest_alpaca_market_data_to_s3_daily`, a pipeline fetching daily multi-asset candlestick records from the Alpaca Markets API. Payloads are transformed from memory objects into clean JSON strings and written to cloud storage.
*   **Storage:** Provisioned a private **AWS S3 bucket** as a Bronze-layer landing zone, using dynamic timestamp partitioning (`market_data_YYYY-MM-DD.json`).

### 2. Cloud Data Warehouse & Analytics Engineering
*   **Keyless IAM Security Bridge:** Removed hardcoded static credentials by configuring an AWS IAM Custom Trust Policy using Snowflake's `STORAGE_AWS_IAM_USER_ARN` and a unique `sts:ExternalId`, granting Snowflake strict read-only access to S3 without long-lived keys.
*   **Medallion Architecture:**
    *   **Bronze:** Snowflake External File Formats and Stages read S3 JSON files directly via SQL.
    *   **Silver (Staging):** dbt Cloud views cast raw JSON fields into strict schema types (`FLOAT`, `TIMESTAMP`).
    *   **Gold (Marts):** Materialized table `fct_rolling_stock_metrics`, using a SQL window function (`AVG() OVER (ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)`) to calculate 5-day rolling stock price averages.

### 3. Real-Time News Sentiment Enrichment
*   **Streaming Ingestion:** An independent n8n lane polls CNBC global market RSS feeds on a 60-second interval.
*   **LLM Extraction:** Headline text is routed to **Google Gemini 2.5 Flash**, prompted to return structured JSON only — ticker symbol, sentiment (`POSITIVE` / `NEGATIVE` / `NEUTRAL`), and a confidence score.
*   **Input Sanitization:** Headline text is escaped (`.replace(/[']/g, "''")`) before insertion to prevent single quotes in live news text from breaking the SQL insert.

## Tech Stack
*   **Infrastructure/Cloud:** AWS (S3, IAM), Oracle Cloud Infrastructure (OCI), GitHub Version Control
*   **Data Warehouse & Modeling:** Snowflake, dbt Cloud (Jinja, SQL)
*   **Automation & AI:** n8n Workflow Automation, Google Gemini 2.5 Flash, SQL Window Functions

## How to Query the Data

Rolling stock metrics (Gold layer):
```sql
SELECT trading_date, apple_close_price, apple_rolling_5_day_avg
FROM financial_lakehouse.dbt_eoc.fct_rolling_stock_metrics
ORDER BY trading_date DESC;
```

Real-time news sentiment:
```sql
SELECT headline_text, extracted_sentiment, confidence_score, inserted_at
FROM financial_lakehouse.realtime_ai.news_sentiment_analysis
ORDER BY inserted_at DESC;
```

## Known Limitations / Next Steps
This is a personal project, not a production system. Honest gaps, and what I'd tackle next:
*   No automated testing on the dbt models yet (e.g. `not_null`/`unique` checks on the Gold tables)
*   No alerting or monitoring if the n8n workflows fail or the API rate-limits
*   The two lanes (market data and news sentiment) aren't currently joined on a shared key (e.g. ticker + date) — that's the natural next feature to build
*   Single-instance orchestration on one VPS, no redundancy
