# frozen_string_literal: true

require "rails_helper"

RSpec.describe Queries::Analytics::WindowAnomalyQuery do
  it "detects traffic spikes via rolling 7-day SQL window z-score" do
    base = 10.days.ago.to_date
    8.times do |i|
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([
          "INSERT INTO daily_rollups (tenant_id, bucket_date, event_name, event_count, total_amount_cents, created_at, updated_at) VALUES (?, ?, 'checkout', ?, ?, NOW(), NOW())",
          "t_anom", base + i.days, 100 + (i.even? ? 2 : -2), 10_000
        ])
      )
    end
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "INSERT INTO daily_rollups (tenant_id, bucket_date, event_name, event_count, total_amount_cents, created_at, updated_at) VALUES (?, ?, 'checkout', 500, 90000, NOW(), NOW())",
        "t_anom", base + 8.days
      ])
    )

    rows = described_class.call(tenant_id: "t_anom", event_name: "checkout", since_date: base - 1.day, z_threshold: 2.0)
    latest = rows.first
    expect(latest["event_count"]).to eq(500)
    expect(latest["is_anomaly"]).to be(true)
    expect(latest["z_score"].to_f).to be > 10.0
  end
end
