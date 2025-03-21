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

ActiveRecord::Schema[8.0].define(version: 2025_03_21_022638) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contact_submissions", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "subject"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "read", default: false
    t.datetime "read_at"
    t.datetime "terms_accepted_at"
    t.boolean "terms", default: false
    t.index ["email"], name: "index_contact_submissions_on_email", unique: true
    t.index ["read"], name: "index_contact_submissions_on_read"
    t.index ["read_at"], name: "index_contact_submissions_on_read_at"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "method_type", null: false
    t.string "provider", null: false
    t.string "account_number_digest"
    t.string "account_name"
    t.string "phone_number"
    t.string "masked_number"
    t.string "expiry_date"
    t.string "card_type"
    t.boolean "default", default: false
    t.integer "status", default: 0, null: false
    t.integer "verification_status", default: 0, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_payment_methods_on_status"
    t.index ["user_id", "default"], name: "index_payment_methods_on_user_id_and_default"
    t.index ["user_id", "method_type"], name: "index_payment_methods_on_user_id_and_method_type"
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "scheduled_transactions", force: :cascade do |t|
    t.bigint "source_wallet_id", null: false
    t.bigint "destination_wallet_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "transaction_type", default: 0, null: false
    t.integer "frequency", default: 2, null: false
    t.datetime "next_occurrence", null: false
    t.datetime "last_occurrence"
    t.integer "status", default: 0, null: false
    t.integer "occurrences_count", default: 0
    t.integer "occurrences_limit"
    t.string "description"
    t.string "payment_method"
    t.string "payment_provider"
    t.string "payment_destination"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_wallet_id"], name: "index_scheduled_transactions_on_destination_wallet_id"
    t.index ["next_occurrence"], name: "index_scheduled_transactions_on_next_occurrence"
    t.index ["source_wallet_id"], name: "index_scheduled_transactions_on_source_wallet_id"
    t.index ["status"], name: "index_scheduled_transactions_on_status"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "transaction_id", null: false
    t.integer "transaction_type", null: false
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "GHS", null: false
    t.decimal "fee", precision: 8, scale: 2, default: "0.0", null: false
    t.bigint "source_wallet_id"
    t.bigint "destination_wallet_id"
    t.string "external_reference"
    t.string "provider_reference"
    t.integer "payment_method"
    t.string "provider"
    t.string "description"
    t.jsonb "metadata", default: {}
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "initiated_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.datetime "reversed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_wallet_id"], name: "index_transactions_on_destination_wallet_id"
    t.index ["initiated_at"], name: "index_transactions_on_initiated_at"
    t.index ["payment_method"], name: "index_transactions_on_payment_method"
    t.index ["provider"], name: "index_transactions_on_provider"
    t.index ["source_wallet_id"], name: "index_transactions_on_source_wallet_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["transaction_id"], name: "index_transactions_on_transaction_id", unique: true
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "theme_preference"
    t.string "language"
    t.string "currency_display"
    t.boolean "email_notifications"
    t.boolean "sms_notifications"
    t.boolean "push_notifications"
    t.boolean "deposit_alerts"
    t.boolean "withdrawal_alerts"
    t.boolean "transfer_alerts"
    t.boolean "low_balance_alerts"
    t.boolean "login_alerts"
    t.boolean "password_alerts"
    t.boolean "product_updates"
    t.boolean "promotional_emails"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_user_settings_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_user_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "phone", default: "", null: false
    t.datetime "phone_verified_at"
    t.integer "kyc_level", default: 0
    t.integer "status", default: 0
    t.string "pin_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "wallet_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "GHS", null: false
    t.decimal "daily_limit", precision: 10, scale: 2, default: "1000.0", null: false
    t.datetime "last_transaction_at"
    t.string "last_ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id"
    t.index ["wallet_id"], name: "index_wallets_on_wallet_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "scheduled_transactions", "wallets", column: "destination_wallet_id"
  add_foreign_key "scheduled_transactions", "wallets", column: "source_wallet_id"
  add_foreign_key "transactions", "wallets", column: "destination_wallet_id"
  add_foreign_key "transactions", "wallets", column: "source_wallet_id"
  add_foreign_key "user_settings", "users"
  add_foreign_key "wallets", "users"
end
