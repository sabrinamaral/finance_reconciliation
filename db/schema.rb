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

ActiveRecord::Schema[8.1].define(version: 2026_07_19_233344) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_periods", force: :cascade do |t|
    t.bigint "audit_id", null: false
    t.datetime "created_at", null: false
    t.integer "month"
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["audit_id"], name: "index_audit_periods_on_audit_id"
  end

  create_table "audits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_audits_on_user_id"
  end

  create_table "cash_flows", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.integer "transaction_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_cash_flows_on_user_id"
  end

  create_table "finance_record2s", force: :cascade do |t|
    t.decimal "amount"
    t.bigint "audit_period_id"
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.boolean "reconciled", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["audit_period_id"], name: "index_finance_record2s_on_audit_period_id"
    t.index ["user_id"], name: "index_finance_record2s_on_user_id"
  end

  create_table "finance_records", force: :cascade do |t|
    t.decimal "amount"
    t.bigint "audit_period_id"
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.boolean "reconciled", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["audit_period_id"], name: "index_finance_records_on_audit_period_id"
    t.index ["user_id"], name: "index_finance_records_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "audit_periods", "audits"
  add_foreign_key "audits", "users"
  add_foreign_key "cash_flows", "users"
  add_foreign_key "finance_record2s", "audit_periods"
  add_foreign_key "finance_record2s", "users"
  add_foreign_key "finance_records", "audit_periods"
  add_foreign_key "finance_records", "users"
end
