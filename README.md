# SQLPulse Rails Analytics

High-throughput event ingestion & PostgreSQL raw SQL analytics engine on **Ruby 3.3, Rails 7.2, Grape API, Dry-rb, PostgreSQL (Declarative Range Partitioning, BRIN, GIN, `UNNEST` Batch Upsert, Window Functions), and RSpec**.

Inspired by `market-columnar-engine` and `tabularis` SQL export workflows.

## Key Features
- **Declarative PostgreSQL Range Partitioning (`PARTITION BY RANGE (occurred_at)`)** with BRIN indexes for time-series scans and GIN indexes on JSONB `properties`.
- **Zero-ORM `UNNEST` Batch Ingestion (`Ingestion::BulkUpsertEvents`)**: Single-roundtrip PostgreSQL batch insert with `ON CONFLICT DO NOTHING` deduplication and incremental `daily_rollups` upsert.
- **SQL Window Anomaly Detector (`Queries::Analytics::WindowAnomalyQuery`)**: Rolling 7-day baseline `AVG` + `STDDEV_POP` + `LAG` Z-score spike detection.
- **SQL Cohort Retention (`Queries::Analytics::CohortRetentionQuery`)**: D0/D1/D7 user retention via CTEs and `FILTER (WHERE ...)`.
- **Keyset NDJSON Exporter (`Exports::KeysetNdjsonExporter`)**: Cursor-based streaming export with zero `OFFSET` scans.

## Run Tests & Linters
```bash
bin/rails db:prepare
bundle exec rspec --format documentation
bin/rubocop
```
