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

ActiveRecord::Schema[8.0].define(version: 2025_04_15_163500) do
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

  create_table "attendances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.integer "status", default: 0
    t.datetime "checked_in_at"
    t.datetime "cancelled_at"
    t.text "additional_info"
    t.jsonb "form_responses", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ticket_code"
    t.text "notes"
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["status"], name: "index_attendances_on_status"
    t.index ["user_id", "event_id"], name: "index_attendances_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "icon"
    t.string "color_code"
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
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

  create_table "event_categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "icon"
    t.bigint "parent_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color_code"
    t.integer "display_order", default: 0
    t.index ["parent_category_id", "name"], name: "index_event_categories_on_parent_category_id_and_name", unique: true
    t.index ["parent_category_id"], name: "index_event_categories_on_parent_category_id"
  end

  create_table "event_comments", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.bigint "parent_comment_id"
    t.text "content", null: false
    t.boolean "is_hidden", default: false
    t.integer "likes_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_approved", default: true
    t.index ["event_id"], name: "index_event_comments_on_event_id"
    t.index ["parent_comment_id"], name: "index_event_comments_on_parent_comment_id"
    t.index ["user_id"], name: "index_event_comments_on_user_id"
  end

  create_table "event_favorites", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_favorites_on_event_id"
    t.index ["user_id", "event_id"], name: "index_event_favorites_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_event_favorites_on_user_id"
  end

  create_table "event_media", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.integer "media_type", null: false
    t.string "title"
    t.text "description"
    t.boolean "is_featured", default: false
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.text "caption"
    t.index ["event_id", "media_type"], name: "index_event_media_on_event_id_and_media_type"
    t.index ["event_id"], name: "index_event_media_on_event_id"
    t.index ["user_id"], name: "index_event_media_on_user_id"
  end

  create_table "event_tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.bigint "ticket_type_id", null: false
    t.bigint "attendance_id", null: false
    t.string "ticket_code", null: false
    t.integer "status", default: 0
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "used_at"
    t.datetime "refunded_at"
    t.string "payment_reference"
    t.string "transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_id"], name: "index_event_tickets_on_attendance_id"
    t.index ["event_id"], name: "index_event_tickets_on_event_id"
    t.index ["status"], name: "index_event_tickets_on_status"
    t.index ["ticket_code"], name: "index_event_tickets_on_ticket_code", unique: true
    t.index ["ticket_type_id"], name: "index_event_tickets_on_ticket_type_id"
    t.index ["user_id"], name: "index_event_tickets_on_user_id"
  end

  create_table "event_views", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id"
    t.string "ip_address", null: false
    t.string "user_agent"
    t.string "referer"
    t.string "referrer"
    t.datetime "viewed_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "ip_address", "created_at"], name: "index_event_views_on_event_id_and_ip_address_and_created_at"
    t.index ["event_id"], name: "index_event_views_on_event_id"
    t.index ["user_id"], name: "index_event_views_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.text "short_description"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.integer "capacity"
    t.integer "status", default: 0
    t.boolean "is_featured", default: false
    t.boolean "is_private", default: false
    t.string "access_code"
    t.string "slug", null: false
    t.bigint "organizer_id", null: false
    t.bigint "event_category_id", null: false
    t.bigint "venue_id", null: false
    t.integer "recurrence_type", default: 0
    t.jsonb "recurrence_pattern"
    t.bigint "parent_event_id"
    t.integer "favorites_count", default: 0
    t.integer "views_count", default: 0
    t.jsonb "custom_fields", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_free", default: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.string "event_type"
    t.bigint "category_id"
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["event_category_id"], name: "index_events_on_event_category_id"
    t.index ["is_featured"], name: "index_events_on_is_featured"
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["parent_event_id"], name: "index_events_on_parent_event_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["start_time"], name: "index_events_on_start_time"
    t.index ["status"], name: "index_events_on_status"
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "favoritable_type", null: false
    t.bigint "favoritable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["favoritable_type", "favoritable_id"], name: "index_favorites_on_favoritable"
    t.index ["user_id", "favoritable_type", "favoritable_id"], name: "index_favorites_on_user_and_favoritable", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "navigation_items", force: :cascade do |t|
    t.string "title", null: false
    t.string "path"
    t.string "icon"
    t.integer "position", default: 0
    t.boolean "active", default: true
    t.integer "required_role"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_navigation_items_on_active"
    t.index ["parent_id"], name: "index_navigation_items_on_parent_id"
    t.index ["position"], name: "index_navigation_items_on_position"
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

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "ticket_types", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "quantity"
    t.datetime "sales_start_time"
    t.datetime "sales_end_time"
    t.integer "sold_count", default: 0
    t.integer "max_per_user"
    t.boolean "transferable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_ticket_types_on_event_id"
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
    t.boolean "admin", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "address", null: false
    t.string "city", null: false
    t.string "region"
    t.string "postal_code"
    t.string "country", default: "Ghana"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "capacity"
    t.jsonb "facilities", default: {}
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.string "phone"
    t.string "state"
    t.index ["city"], name: "index_venues_on_city"
    t.index ["latitude", "longitude"], name: "index_venues_on_latitude_and_longitude"
    t.index ["name"], name: "index_venues_on_name"
    t.index ["user_id"], name: "index_venues_on_user_id"
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
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "event_categories", "event_categories", column: "parent_category_id"
  add_foreign_key "event_comments", "event_comments", column: "parent_comment_id"
  add_foreign_key "event_comments", "events"
  add_foreign_key "event_comments", "users"
  add_foreign_key "event_favorites", "events"
  add_foreign_key "event_favorites", "users"
  add_foreign_key "event_media", "events"
  add_foreign_key "event_media", "users"
  add_foreign_key "event_tickets", "attendances"
  add_foreign_key "event_tickets", "events"
  add_foreign_key "event_tickets", "ticket_types"
  add_foreign_key "event_tickets", "users"
  add_foreign_key "event_views", "events"
  add_foreign_key "event_views", "users"
  add_foreign_key "events", "categories"
  add_foreign_key "events", "event_categories"
  add_foreign_key "events", "events", column: "parent_event_id"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "events", "venues"
  add_foreign_key "favorites", "users"
  add_foreign_key "navigation_items", "navigation_items", column: "parent_id"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "scheduled_transactions", "wallets", column: "destination_wallet_id"
  add_foreign_key "scheduled_transactions", "wallets", column: "source_wallet_id"
  add_foreign_key "ticket_types", "events"
  add_foreign_key "transactions", "wallets", column: "destination_wallet_id"
  add_foreign_key "transactions", "wallets", column: "source_wallet_id"
  add_foreign_key "user_settings", "users"
  add_foreign_key "venues", "users"
  add_foreign_key "wallets", "users"
end
