# frozen_string_literal: true

module Exports
  class KeysetNdjsonExporter
    KEYSET_SQL = <<~SQL.squish
      SELECT id, tenant_id, event_id, user_key, event_name, amount_cents, currency, properties, occurred_at
      FROM analytics_events
      WHERE tenant_id = :tenant_id
        AND (
          occurred_at > :cursor_ts
          OR (occurred_at = :cursor_ts AND id > :cursor_id)
        )
      ORDER BY occurred_at ASC, id ASC
      LIMIT :limit
    SQL

    def self.stream(tenant_id:, batch_size: 500)
      Enumerator.new do |yielder|
        cursor_ts = Time.utc(1970, 1, 1)
        cursor_id = 0

        loop do
          sql = ActiveRecord::Base.sanitize_sql_array([
            KEYSET_SQL,
            { tenant_id: tenant_id, cursor_ts: cursor_ts, cursor_id: cursor_id, limit: batch_size }
          ])
          rows = ActiveRecord::Base.connection.exec_query(sql).to_a
          break if rows.empty?

          rows.each { |row| yielder << "#{row.to_json}\n" }
          last = rows.last
          cursor_ts = last.fetch("occurred_at")
          cursor_id = last.fetch("id").to_i
          break if rows.size < batch_size
        end
      end
    end
  end
end
