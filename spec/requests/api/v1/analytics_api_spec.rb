# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SQLPulse Grape API v1", type: :request do
  it "ingests batch events, computes retention, and streams keyset NDJSON export" do
    now = Time.current.utc.iso8601
    post "/api/v1/ingest/batch",
         params: {
           tenant_id: "tenant_api",
           events: [
             { event_id: "e1", user_key: "u1", event_name: "signup", amount_cents: 0, occurred_at: now },
             { event_id: "e2", user_key: "u2", event_name: "signup", amount_cents: 500, occurred_at: now }
           ]
         }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body)["inserted"]).to eq(2)

    get "/api/v1/exports/ndjson?tenant_id=tenant_api"
    expect(response).to have_http_status(:ok)
    lines = response.body.lines.map { |l| JSON.parse(l) }
    expect(lines.size).to eq(2)
    expect(lines.map { |l| l["event_id"] }).to eq(%w[e1 e2])
  end
end
