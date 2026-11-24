# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ingestion::BulkUpsertEvents do
  subject(:service) { described_class.new }

  it "bulk-inserts partitioned events via UNNEST, deduplicates replays, and updates daily rollups" do
    now = Time.current.utc
    payload = {
      tenant_id: "shop_kz_1",
      events: [
        { event_id: "ev_1", user_key: "u1", event_name: "purchase", amount_cents: 1500, currency: "KZT", occurred_at: now },
        { event_id: "ev_2", user_key: "u2", event_name: "purchase", amount_cents: 2500, currency: "KZT", occurred_at: now }
      ]
    }

    first = service.call(payload)
    expect(first).to be_success
    expect(first.value!).to eq({ received: 2, inserted: 2, deduplicated: 0 })

    # Replay same batch + 1 new event
    second = service.call(
      tenant_id: "shop_kz_1",
      events: payload[:events] + [
        { event_id: "ev_3", user_key: "u1", event_name: "purchase", amount_cents: 1000, currency: "KZT", occurred_at: now + 1.day }
      ]
    )

    expect(second).to be_success
    expect(second.value!).to eq({ received: 3, inserted: 1, deduplicated: 2 })

    cohorts = Queries::Analytics::CohortRetentionQuery.call(tenant_id: "shop_kz_1", since: 2.days.ago)
    expect(cohorts.first["d0_users"]).to eq(2)
    expect(cohorts.first["d1_users"]).to eq(1)
    expect(cohorts.first["d1_retention_pct"].to_f).to eq(50.0)
  end
end
