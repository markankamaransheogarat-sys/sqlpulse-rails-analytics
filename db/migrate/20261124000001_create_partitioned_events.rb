# frozen_string_literal: true

class CreatePartitionedEvents < ActiveRecord::Migration[7.2]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE TABLE analytics_events (
        id BIGSERIAL,
        tenant_id VARCHAR(64) NOT NULL,
        event_id VARCHAR(128) NOT NULL,
        user_key VARCHAR(128) NOT NULL,
        event_name VARCHAR(64) NOT NULL,
        amount_cents BIGINT NOT NULL DEFAULT 0,
        currency VARCHAR(3) NOT NULL DEFAULT 'USD',
        properties JSONB NOT NULL DEFAULT '{}'::jsonb,
        occurred_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id, occurred_at),
        CONSTRAINT uq_analytics_events_idempotency UNIQUE (tenant_id, event_id, occurred_at)
      ) PARTITION BY RANGE (occurred_at);

      CREATE INDEX idx_analytics_events_occurred_brin
        ON analytics_events USING brin (occurred_at) WITH (pages_per_range = 32);

      CREATE INDEX idx_analytics_events_tenant_name
        ON analytics_events (tenant_id, event_name, occurred_at DESC);

      CREATE INDEX idx_analytics_events_props_gin
        ON analytics_events USING gin (properties);

      CREATE TABLE analytics_events_default
        PARTITION OF analytics_events DEFAULT;
    SQL

    # Pre-create current and adjacent monthly partitions
    [ -1, 0, 1 ].each do |month_offset|
      month_start = Time.current.utc.beginning_of_month + month_offset.months
      month_end = month_start + 1.month
      suffix = month_start.strftime("y%Ym%m")
      execute <<~SQL
        CREATE TABLE analytics_events_#{suffix}
          PARTITION OF analytics_events
          FOR VALUES FROM ('#{month_start.strftime('%Y-%m-%d 00:00:00+00')}')
          TO ('#{month_end.strftime('%Y-%m-%d 00:00:00+00')}');
      SQL
    end

    create_table :daily_rollups do |t|
      t.string :tenant_id, null: false
      t.date :bucket_date, null: false
      t.string :event_name, null: false
      t.bigint :event_count, null: false, default: 0
      t.bigint :total_amount_cents, null: false, default: 0
      t.timestamps
    end

    add_index :daily_rollups, %i[tenant_id bucket_date event_name],
              unique: true,
              name: "idx_daily_rollups_unique"
  end

  def down
    drop_table :daily_rollups, if_exists: true
    execute "DROP TABLE IF EXISTS analytics_events CASCADE;"
  end
end
