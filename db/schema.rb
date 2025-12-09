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

ActiveRecord::Schema[8.1].define(version: 2025_12_09_031341) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.datetime "acknowledged_at"
    t.decimal "actual_value", precision: 10, scale: 4
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.bigint "edge_site_id", null: false
    t.text "message"
    t.string "metric_type"
    t.datetime "resolved_at"
    t.integer "severity", default: 0, null: false
    t.integer "status", default: 0
    t.decimal "threshold_value", precision: 10, scale: 4
    t.string "title", null: false
    t.datetime "triggered_at", null: false
    t.datetime "updated_at", null: false
    t.index ["edge_site_id", "status"], name: "idx_alerts_site_status"
    t.index ["edge_site_id"], name: "index_alerts_on_edge_site_id"
    t.index ["severity"], name: "index_alerts_on_severity"
    t.index ["status"], name: "index_alerts_on_status"
    t.index ["triggered_at"], name: "index_alerts_on_triggered_at"
  end

  create_table "edge_sites", force: :cascade do |t|
    t.string "api_endpoint", null: false
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.string "environment", default: "production"
    t.datetime "last_seen_at"
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.string "region"
    t.string "slug", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_edge_sites_on_name"
    t.index ["region"], name: "index_edge_sites_on_region"
    t.index ["slug"], name: "index_edge_sites_on_slug", unique: true
    t.index ["status"], name: "index_edge_sites_on_status"
  end

  create_table "metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edge_site_id", null: false
    t.jsonb "labels", default: {}
    t.string "metric_type", null: false
    t.string "namespace"
    t.string "node_name"
    t.string "pod_name"
    t.datetime "recorded_at", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 10, scale: 4, null: false
    t.index ["edge_site_id", "metric_type", "recorded_at"], name: "idx_metrics_site_type_time"
    t.index ["edge_site_id"], name: "index_metrics_on_edge_site_id"
    t.index ["metric_type"], name: "index_metrics_on_metric_type"
    t.index ["recorded_at"], name: "index_metrics_on_recorded_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "alerts", "edge_sites"
  add_foreign_key "metrics", "edge_sites"
end
