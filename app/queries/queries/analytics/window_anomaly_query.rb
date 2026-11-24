# frozen_string_literal: true

module Queries
  module Analytics
    class WindowAnomalyQuery
      SQL = <<~SQL.squish
        WITH daily_series AS (
          SELECT
            bucket_date,
            event_name,
            event_count,
            total_amount_cents,
            LAG(event_count) OVER (PARTITION BY event_name ORDER BY bucket_date) AS prev_day_count,
            AVG(event_count) OVER (
              PARTITION BY event_name
              ORDER BY bucket_date
              ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
            ) AS baseline_avg,
            STDDEV_POP(event_count) OVER (
              PARTITION BY event_name
              ORDER BY bucket_date
              ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
            ) AS baseline_stddev
          FROM daily_rollups
          WHERE tenant_id = :tenant_id
            AND event_name = :event_name
            AND bucket_date >= :since_date
        )
        SELECT
          bucket_date,
          event_name,
          event_count,
          total_amount_cents,
          prev_day_count,
          ROUND(baseline_avg, 2) AS baseline_avg,
          ROUND(
            (event_count - baseline_avg) / NULLIF(baseline_stddev, 0),
            2
          ) AS z_score,
          CASE
            WHEN baseline_stddev > 0 AND ABS((event_count - baseline_avg) / baseline_stddev) >= :z_threshold THEN TRUE
            ELSE FALSE
          END AS is_anomaly
        FROM daily_series
        ORDER BY bucket_date DESC
      SQL

      def self.call(tenant_id:, event_name:, since_date: 30.days.ago.to_date, z_threshold: 2.0)
        sql = ActiveRecord::Base.sanitize_sql_array([
          SQL,
          {
            tenant_id: tenant_id,
            event_name: event_name,
            since_date: since_date,
            z_threshold: z_threshold
          }
        ])

        ActiveRecord::Base.connection.exec_query(sql).to_a
      end
    end
  end
end
