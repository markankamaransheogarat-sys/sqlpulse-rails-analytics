# frozen_string_literal: true

module Ingestion
  class BulkUpsertEvents
    include Dry::Monads[:result, :do]

    UNNEST_INSERT_SQL = <<~SQL.squish
      WITH incoming AS (
        SELECT
          :tenant_id::varchar AS tenant_id,
          u.event_id,
          u.user_key,
          u.event_name,
          u.amount_cents,
          u.currency,
          u.properties::jsonb AS properties,
          u.occurred_at
        FROM UNNEST(
          ARRAY[:event_ids]::varchar[],
          ARRAY[:user_keys]::varchar[],
          ARRAY[:event_names]::varchar[],
          ARRAY[:amounts]::bigint[],
          ARRAY[:currencies]::varchar[],
          ARRAY[:props]::text[],
          ARRAY[:occurred_ats]::timestamptz[]
        ) AS u(event_id, user_key, event_name, amount_cents, currency, properties, occurred_at)
      ),
      inserted AS (
        INSERT INTO analytics_events (
          tenant_id, event_id, user_key, event_name, amount_cents, currency, properties, occurred_at, created_at
        )
        SELECT
          tenant_id, event_id, user_key, event_name, amount_cents, currency, properties, occurred_at, NOW()
        FROM incoming
        ON CONFLICT (tenant_id, event_id, occurred_at) DO NOTHING
        RETURNING tenant_id, DATE(occurred_at AT TIME ZONE 'UTC') AS bucket_date, event_name, amount_cents
      ),
      agg AS (
        SELECT
          tenant_id,
          bucket_date,
          event_name,
          COUNT(*)::bigint AS cnt,
          COALESCE(SUM(amount_cents), 0)::bigint AS sum_cents
        FROM inserted
        GROUP BY tenant_id, bucket_date, event_name
      ),
      rollups AS (
        INSERT INTO daily_rollups (tenant_id, bucket_date, event_name, event_count, total_amount_cents, created_at, updated_at)
        SELECT tenant_id, bucket_date, event_name, cnt, sum_cents, NOW(), NOW()
        FROM agg
        ON CONFLICT (tenant_id, bucket_date, event_name)
        DO UPDATE SET
          event_count = daily_rollups.event_count + EXCLUDED.event_count,
          total_amount_cents = daily_rollups.total_amount_cents + EXCLUDED.total_amount_cents,
          updated_at = NOW()
      )
      SELECT COUNT(*)::int AS inserted_count FROM inserted
    SQL

    def initialize(contract: Contracts::Ingestion::BatchContract.new)
      @contract = contract
    end

    def call(params)
      validated = yield validate(params)
      events = validated[:events]

      sql = ActiveRecord::Base.sanitize_sql_array([
        UNNEST_INSERT_SQL,
        {
          tenant_id: validated[:tenant_id],
          event_ids: events.map { |e| e[:event_id] },
          user_keys: events.map { |e| e[:user_key] },
          event_names: events.map { |e| e[:event_name] },
          amounts: events.map { |e| e.fetch(:amount_cents, 0) },
          currencies: events.map { |e| e.fetch(:currency, "USD") },
          props: events.map { |e| (e[:properties] || {}).to_json },
          occurred_ats: events.map { |e| e[:occurred_at].utc.iso8601(6) }
        }
      ])

      row = ActiveRecord::Base.connection.exec_query(sql).first
      inserted_count = row.fetch("inserted_count").to_i

      Success(
        received: events.size,
        inserted: inserted_count,
        deduplicated: events.size - inserted_count
      )
    end

    private

    def validate(params)
      res = @contract.call(params)
      res.success? ? Success(res.to_h) : Failure([ :validation_error, res.errors.to_h ])
    end
  end
end
