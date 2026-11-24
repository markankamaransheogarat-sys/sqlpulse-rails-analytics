# frozen_string_literal: true

module Queries
  module Analytics
    class CohortRetentionQuery
      SQL = <<~SQL.squish
        WITH user_cohorts AS (
          SELECT
            user_key,
            MIN(DATE(occurred_at AT TIME ZONE 'UTC')) AS cohort_date
          FROM analytics_events
          WHERE tenant_id = :tenant_id
            AND occurred_at >= :since
          GROUP BY user_key
        ),
        activity AS (
          SELECT DISTINCT
            e.user_key,
            uc.cohort_date,
            (DATE(e.occurred_at AT TIME ZONE 'UTC') - uc.cohort_date)::int AS day_offset
          FROM analytics_events e
          INNER JOIN user_cohorts uc ON uc.user_key = e.user_key
          WHERE e.tenant_id = :tenant_id
            AND e.occurred_at >= :since
        )
        SELECT
          cohort_date,
          COUNT(*) FILTER (WHERE day_offset = 0) AS d0_users,
          COUNT(*) FILTER (WHERE day_offset = 1) AS d1_users,
          COUNT(*) FILTER (WHERE day_offset = 7) AS d7_users,
          ROUND(
            100.0 * COUNT(*) FILTER (WHERE day_offset = 1) / NULLIF(COUNT(*) FILTER (WHERE day_offset = 0), 0),
            2
          ) AS d1_retention_pct
        FROM activity
        GROUP BY cohort_date
        ORDER BY cohort_date DESC
      SQL

      def self.call(tenant_id:, since: 30.days.ago)
        sql = ActiveRecord::Base.sanitize_sql_array([ SQL, { tenant_id: tenant_id, since: since } ])
        ActiveRecord::Base.connection.exec_query(sql).to_a
      end
    end
  end
end
