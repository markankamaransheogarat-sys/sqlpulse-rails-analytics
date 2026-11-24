# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_11_24_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "analytics_events", primary_key: ["id", "occurred_at"], force: :cascade do |t|
    t.bigserial "id", null: false
    t.string "tenant_id", limit: 64, null: false
    t.string "event_id", limit: 128, null: false
    t.string "user_key", limit: 128, null: false
    t.string "event_name", limit: 64, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.jsonb "properties", default: {}, null: false
    t.timestamptz "occurred_at", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.index ["occurred_at"], name: "idx_analytics_events_occurred_brin", using: :brin
    t.index ["properties"], name: "idx_analytics_events_props_gin", using: :gin
    t.index ["tenant_id", "event_name", "occurred_at"], name: "idx_analytics_events_tenant_name", order: { occurred_at: :desc }
    t.unique_constraint ["tenant_id", "event_id", "occurred_at"], name: "uq_analytics_events_idempotency"
  end

  create_table "analytics_events_default", primary_key: ["id", "occurred_at"], force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('analytics_events_id_seq'::regclass)" }, null: false
    t.string "tenant_id", limit: 64, null: false
    t.string "event_id", limit: 128, null: false
    t.string "user_key", limit: 128, null: false
    t.string "event_name", limit: 64, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.jsonb "properties", default: {}, null: false
    t.timestamptz "occurred_at", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.index ["occurred_at"], name: "analytics_events_default_occurred_at_idx", using: :brin
    t.index ["properties"], name: "analytics_events_default_properties_idx", using: :gin
    t.index ["tenant_id", "event_name", "occurred_at"], name: "analytics_events_default_tenant_id_event_name_occurred_at_idx", order: { occurred_at: :desc }
    t.unique_constraint ["tenant_id", "event_id", "occurred_at"], name: "analytics_events_default_tenant_id_event_id_occurred_at_key"
  end

  create_table "analytics_events_y2026m10", primary_key: ["id", "occurred_at"], force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('analytics_events_id_seq'::regclass)" }, null: false
    t.string "tenant_id", limit: 64, null: false
    t.string "event_id", limit: 128, null: false
    t.string "user_key", limit: 128, null: false
    t.string "event_name", limit: 64, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.jsonb "properties", default: {}, null: false
    t.timestamptz "occurred_at", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.index ["occurred_at"], name: "analytics_events_y2026m10_occurred_at_idx", using: :brin
    t.index ["properties"], name: "analytics_events_y2026m10_properties_idx", using: :gin
    t.index ["tenant_id", "event_name", "occurred_at"], name: "analytics_events_y2026m10_tenant_id_event_name_occurred_at_idx", order: { occurred_at: :desc }
    t.unique_constraint ["tenant_id", "event_id", "occurred_at"], name: "analytics_events_y2026m10_tenant_id_event_id_occurred_at_key"
  end

  create_table "analytics_events_y2026m11", primary_key: ["id", "occurred_at"], force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('analytics_events_id_seq'::regclass)" }, null: false
    t.string "tenant_id", limit: 64, null: false
    t.string "event_id", limit: 128, null: false
    t.string "user_key", limit: 128, null: false
    t.string "event_name", limit: 64, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.jsonb "properties", default: {}, null: false
    t.timestamptz "occurred_at", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.index ["occurred_at"], name: "analytics_events_y2026m11_occurred_at_idx", using: :brin
    t.index ["properties"], name: "analytics_events_y2026m11_properties_idx", using: :gin
    t.index ["tenant_id", "event_name", "occurred_at"], name: "analytics_events_y2026m11_tenant_id_event_name_occurred_at_idx", order: { occurred_at: :desc }
    t.unique_constraint ["tenant_id", "event_id", "occurred_at"], name: "analytics_events_y2026m11_tenant_id_event_id_occurred_at_key"
  end

  create_table "analytics_events_y2026m12", primary_key: ["id", "occurred_at"], force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('analytics_events_id_seq'::regclass)" }, null: false
    t.string "tenant_id", limit: 64, null: false
    t.string "event_id", limit: 128, null: false
    t.string "user_key", limit: 128, null: false
    t.string "event_name", limit: 64, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.jsonb "properties", default: {}, null: false
    t.timestamptz "occurred_at", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.index ["occurred_at"], name: "analytics_events_y2026m12_occurred_at_idx", using: :brin
    t.index ["properties"], name: "analytics_events_y2026m12_properties_idx", using: :gin
    t.index ["tenant_id", "event_name", "occurred_at"], name: "analytics_events_y2026m12_tenant_id_event_name_occurred_at_idx", order: { occurred_at: :desc }
    t.unique_constraint ["tenant_id", "event_id", "occurred_at"], name: "analytics_events_y2026m12_tenant_id_event_id_occurred_at_key"
  end

  create_table "daily_rollups", force: :cascade do |t|
    t.string "tenant_id", null: false
    t.date "bucket_date", null: false
    t.string "event_name", null: false
    t.bigint "event_count", default: 0, null: false
    t.bigint "total_amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "bucket_date", "event_name"], name: "idx_daily_rollups_unique", unique: true
  end
end
