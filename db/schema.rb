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

ActiveRecord::Schema[8.0].define(version: 2025_04_29_000005) do
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

  create_table "agriculture_resources", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.bigint "crop_id"
    t.bigint "user_id"
    t.integer "resource_type", default: 0
    t.boolean "published", default: true
    t.boolean "featured", default: false
    t.datetime "published_at"
    t.integer "view_count", default: 0
    t.string "external_url"
    t.string "video_url"
    t.string "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crop_id"], name: "index_agriculture_resources_on_crop_id"
    t.index ["featured"], name: "index_agriculture_resources_on_featured"
    t.index ["published"], name: "index_agriculture_resources_on_published"
    t.index ["resource_type"], name: "index_agriculture_resources_on_resource_type"
    t.index ["user_id"], name: "index_agriculture_resources_on_user_id"
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

  create_table "beneficiaries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "account_number", null: false
    t.string "bank_name"
    t.string "phone_number"
    t.integer "transfer_type", default: 0, null: false
    t.integer "usage_count", default: 0, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "account_number"], name: "index_beneficiaries_on_user_id_and_account_number", unique: true
    t.index ["user_id"], name: "index_beneficiaries_on_user_id"
  end

  create_table "bill_payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "transaction_id"
    t.integer "bill_type", default: 0, null: false
    t.string "provider", null: false
    t.string "account_number", null: false
    t.string "package"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "fee", precision: 10, scale: 2, default: "0.0"
    t.integer "status", default: 0, null: false
    t.string "reference_number"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_number"], name: "index_bill_payments_on_reference_number", unique: true
    t.index ["transaction_id"], name: "index_bill_payments_on_transaction_id"
    t.index ["user_id"], name: "index_bill_payments_on_user_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "session_id"
    t.datetime "abandoned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_carts_on_session_id", unique: true
    t.index ["user_id"], name: "index_carts_on_user_id"
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

  create_table "coupons", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "value", precision: 10, scale: 2, null: false
    t.string "discount_type", default: "percentage", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean "active", default: true
    t.integer "usage_limit"
    t.integer "usage_count", default: 0
    t.decimal "minimum_order_amount", precision: 10, scale: 2
    t.bigint "shop_category_id"
    t.boolean "first_time_purchase_only", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
    t.index ["shop_category_id"], name: "index_coupons_on_shop_category_id"
  end

  create_table "credit_improvement_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "starting_score", null: false
    t.integer "target_score", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_credit_improvement_plans_on_user_id_and_status"
    t.index ["user_id"], name: "index_credit_improvement_plans_on_user_id"
  end

  create_table "credit_improvement_steps", force: :cascade do |t|
    t.bigint "credit_improvement_plan_id", null: false
    t.string "action", null: false
    t.text "description", null: false
    t.integer "impact", null: false
    t.integer "timeframe", default: 0, null: false
    t.integer "difficulty", default: 0, null: false
    t.integer "category", default: 4, null: false
    t.integer "status", default: 0, null: false
    t.integer "position", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_improvement_plan_id", "position"], name: "idx_on_credit_improvement_plan_id_position_ca0bb73854"
    t.index ["credit_improvement_plan_id", "status"], name: "idx_on_credit_improvement_plan_id_status_598a1d27a8"
    t.index ["credit_improvement_plan_id"], name: "index_credit_improvement_steps_on_credit_improvement_plan_id"
  end

  create_table "credit_scores", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "score", null: false
    t.text "factors"
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_current", default: true
    t.index ["is_current"], name: "index_credit_scores_on_is_current"
    t.index ["score"], name: "index_credit_scores_on_score"
    t.index ["user_id"], name: "index_credit_scores_on_user_id"
  end

  create_table "crop_listing_inquiries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "crop_listing_id", null: false
    t.text "message", null: false
    t.text "response"
    t.integer "status", default: 0
    t.boolean "read", default: false
    t.decimal "quantity"
    t.decimal "offered_price", precision: 10, scale: 2
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crop_listing_id"], name: "index_crop_listing_inquiries_on_crop_listing_id"
    t.index ["read"], name: "index_crop_listing_inquiries_on_read"
    t.index ["status"], name: "index_crop_listing_inquiries_on_status"
    t.index ["user_id"], name: "index_crop_listing_inquiries_on_user_id"
  end

  create_table "crop_listings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "crop_id", null: false
    t.bigint "region_id"
    t.string "title", null: false
    t.text "description", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "unit", default: "kg", null: false
    t.integer "listing_type", default: 0
    t.integer "status", default: 0
    t.boolean "featured", default: false
    t.boolean "negotiable", default: true
    t.date "expiry_date"
    t.datetime "sold_at"
    t.string "location"
    t.text "terms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crop_id"], name: "index_crop_listings_on_crop_id"
    t.index ["featured"], name: "index_crop_listings_on_featured"
    t.index ["listing_type"], name: "index_crop_listings_on_listing_type"
    t.index ["region_id"], name: "index_crop_listings_on_region_id"
    t.index ["status"], name: "index_crop_listings_on_status"
    t.index ["user_id"], name: "index_crop_listings_on_user_id"
  end

  create_table "crop_prices", force: :cascade do |t|
    t.bigint "crop_id", null: false
    t.bigint "region_id"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.date "date", null: false
    t.string "unit", default: "kg", null: false
    t.string "market", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crop_id", "date", "region_id", "market"], name: "index_crop_prices_on_crop_date_region_market"
    t.index ["crop_id"], name: "index_crop_prices_on_crop_id"
    t.index ["region_id"], name: "index_crop_prices_on_region_id"
  end

  create_table "crops", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "scientific_name"
    t.string "growing_season"
    t.integer "season_start"
    t.integer "season_end"
    t.integer "growing_time"
    t.integer "category", default: 0
    t.integer "popularity", default: 0
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_crops_on_category"
    t.index ["featured"], name: "index_crops_on_featured"
    t.index ["name"], name: "index_crops_on_name", unique: true
  end

  create_table "digital_downloads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.bigint "order_item_id", null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_item_id"], name: "index_digital_downloads_on_order_item_id"
    t.index ["product_id"], name: "index_digital_downloads_on_product_id"
    t.index ["user_id", "product_id"], name: "index_digital_downloads_on_user_id_and_product_id"
    t.index ["user_id"], name: "index_digital_downloads_on_user_id"
  end

  create_table "discounts", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "value", precision: 10, scale: 2, null: false
    t.string "discount_type", default: "percentage", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean "active", default: true
    t.integer "usage_limit"
    t.integer "usage_count", default: 0
    t.bigint "shop_category_id"
    t.bigint "product_id"
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_discounts_on_product_id"
    t.index ["shop_category_id"], name: "index_discounts_on_shop_category_id"
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

  create_table "event_tags", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "tag_id"], name: "index_event_tags_on_event_id_and_tag_id", unique: true
    t.index ["event_id"], name: "index_event_tags_on_event_id"
    t.index ["tag_id"], name: "index_event_tags_on_tag_id"
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

  create_table "flash_sale_items", force: :cascade do |t|
    t.bigint "flash_sale_id", null: false
    t.bigint "product_id", null: false
    t.decimal "discount_value", precision: 10, scale: 2, null: false
    t.string "discount_type", default: "percentage", null: false
    t.integer "quantity_limit"
    t.integer "sold_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flash_sale_id", "product_id"], name: "index_flash_sale_items_on_flash_sale_id_and_product_id", unique: true
    t.index ["flash_sale_id"], name: "index_flash_sale_items_on_flash_sale_id"
    t.index ["product_id"], name: "index_flash_sale_items_on_product_id"
  end

  create_table "flash_sales", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.boolean "active", default: true
    t.boolean "featured", default: false
    t.string "banner_text"
    t.string "banner_color", default: "#FF0000"
    t.string "banner_text_color", default: "#FFFFFF"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gathering_attendances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "gathering_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gathering_id"], name: "index_gathering_attendances_on_gathering_id"
    t.index ["user_id", "gathering_id"], name: "index_gathering_attendances_on_user_id_and_gathering_id", unique: true
    t.index ["user_id"], name: "index_gathering_attendances_on_user_id"
  end

  create_table "gatherings", force: :cascade do |t|
    t.bigint "group_id"
    t.bigint "organizer_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.date "date", null: false
    t.time "start_time"
    t.time "end_time"
    t.string "location", null: false
    t.string "image"
    t.string "gathering_type"
    t.boolean "featured", default: false
    t.integer "attendees_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_gatherings_on_group_id"
    t.index ["organizer_id"], name: "index_gatherings_on_organizer_id"
  end

  create_table "group_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "icon"
    t.integer "groups_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_group_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "group_category_id", null: false
    t.string "name", null: false
    t.text "description", null: false
    t.string "image"
    t.string "location"
    t.boolean "featured", default: false
    t.integer "members_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_category_id"], name: "index_groups_on_group_category_id"
  end

  create_table "learning_resources", force: :cascade do |t|
    t.bigint "resource_category_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "file_url", null: false
    t.string "thumbnail"
    t.string "file_type"
    t.string "level"
    t.string "duration"
    t.boolean "featured", default: false
    t.integer "downloads_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_category_id"], name: "index_learning_resources_on_resource_category_id"
  end

  create_table "loan_refinancings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "original_loan_id", null: false
    t.bigint "new_loan_id"
    t.decimal "requested_amount", precision: 10, scale: 2, null: false
    t.decimal "original_rate", precision: 5, scale: 2, null: false
    t.decimal "requested_rate", precision: 5, scale: 2, null: false
    t.decimal "estimated_savings", precision: 10, scale: 2
    t.integer "term_days", null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.text "rejection_reason"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["new_loan_id"], name: "index_loan_refinancings_on_new_loan_id"
    t.index ["original_loan_id"], name: "index_loan_refinancings_on_original_loan_id"
    t.index ["status"], name: "index_loan_refinancings_on_status"
    t.index ["user_id"], name: "index_loan_refinancings_on_user_id"
  end

  create_table "loan_repayments", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.bigint "transaction_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "principal_amount", precision: 10, scale: 2, null: false
    t.decimal "interest_amount", precision: 10, scale: 2, null: false
    t.integer "status", default: 0
    t.date "due_date"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_loan_repayments_on_due_date"
    t.index ["loan_id"], name: "index_loan_repayments_on_loan_id"
    t.index ["status"], name: "index_loan_repayments_on_status"
    t.index ["transaction_id"], name: "index_loan_repayments_on_transaction_id"
  end

  create_table "loans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "reference_number", null: false
    t.integer "loan_type", default: 0
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "interest_rate", precision: 5, scale: 2, null: false
    t.integer "term_months", null: false
    t.date "due_date", null: false
    t.integer "status", default: 0
    t.text "purpose"
    t.integer "credit_score"
    t.decimal "current_balance", precision: 10, scale: 2
    t.datetime "approved_at"
    t.datetime "disbursed_at"
    t.datetime "completed_at"
    t.datetime "defaulted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "term_days"
    t.jsonb "metadata", default: {}
    t.decimal "processing_fee", precision: 10, scale: 2
    t.decimal "amount_due", precision: 10, scale: 2
    t.bigint "refinanced_from_loan_id"
    t.bigint "refinanced_to_loan_id"
    t.index ["loan_type"], name: "index_loans_on_loan_type"
    t.index ["reference_number"], name: "index_loans_on_reference_number", unique: true
    t.index ["refinanced_from_loan_id"], name: "index_loans_on_refinanced_from_loan_id"
    t.index ["refinanced_to_loan_id"], name: "index_loans_on_refinanced_to_loan_id"
    t.index ["status"], name: "index_loans_on_status"
    t.index ["user_id"], name: "index_loans_on_user_id"
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

  create_table "notification_channels", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "channel_type", null: false
    t.string "identifier", null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "verified", default: false, null: false
    t.datetime "verified_at"
    t.string "verification_token"
    t.datetime "verification_sent_at"
    t.integer "verification_attempts", default: 0, null: false
    t.json "settings"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_type", "identifier"], name: "index_notification_channels_on_channel_type_and_identifier", unique: true
    t.index ["user_id", "channel_type"], name: "index_notification_channels_on_user_id_and_channel_type"
    t.index ["user_id"], name: "index_notification_channels_on_user_id"
    t.index ["verification_token"], name: "index_notification_channels_on_verification_token", unique: true
  end

  create_table "notification_deliveries", force: :cascade do |t|
    t.bigint "notification_id", null: false
    t.bigint "notification_channel_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "delivered_at"
    t.datetime "read_at"
    t.text "error_message"
    t.integer "attempts", default: 0, null: false
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_channel_id"], name: "index_notification_deliveries_on_notification_channel_id"
    t.index ["notification_id", "notification_channel_id"], name: "index_notification_deliveries_on_notification_and_channel"
    t.index ["notification_id"], name: "index_notification_deliveries_on_notification_id"
    t.index ["status"], name: "index_notification_deliveries_on_status"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "email_enabled", default: true
    t.boolean "sms_enabled", default: true
    t.boolean "push_enabled", default: true
    t.boolean "in_app_enabled", default: true
    t.jsonb "email_preferences", default: {}
    t.jsonb "sms_preferences", default: {}
    t.jsonb "push_preferences", default: {}
    t.jsonb "in_app_preferences", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.integer "severity", default: 0, null: false
    t.integer "category", default: 0, null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.datetime "sent_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "action_url"
    t.string "action_text"
    t.json "metadata"
    t.string "image_url"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "category"], name: "index_notifications_on_user_id_and_category"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id", "severity"], name: "index_notifications_on_user_id_and_severity"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.jsonb "product_snapshot", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "order_number", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.string "shipping_address"
    t.string "billing_address"
    t.string "payment_method"
    t.bigint "transaction_id"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.datetime "cancelled_at"
    t.string "tracking_number"
    t.text "notes"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "coupon_id"
    t.decimal "coupon_discount", precision: 10, scale: 2, default: "0.0"
    t.index ["coupon_id"], name: "index_orders_on_coupon_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["transaction_id"], name: "index_orders_on_transaction_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
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
    t.string "description"
    t.index ["status"], name: "index_payment_methods_on_status"
    t.index ["user_id", "default"], name: "index_payment_methods_on_user_id_and_default"
    t.index ["user_id", "method_type"], name: "index_payment_methods_on_user_id_and_method_type"
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "original_price", precision: 10, scale: 2
    t.integer "stock_quantity", default: 0, null: false
    t.string "sku", null: false
    t.bigint "shop_category_id"
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.boolean "featured", default: false
    t.string "brand"
    t.jsonb "specifications", default: {}
    t.string "tags", default: [], array: true
    t.decimal "weight"
    t.string "weight_unit"
    t.decimal "length"
    t.decimal "width"
    t.decimal "height"
    t.string "dimension_unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "product_type", default: "physical"
    t.string "digital_file_name"
    t.integer "digital_file_size"
    t.string "digital_content_type"
    t.integer "download_limit", default: 0
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["name"], name: "index_products_on_name"
    t.index ["shop_category_id"], name: "index_products_on_shop_category_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["status"], name: "index_products_on_status"
    t.index ["tags"], name: "index_products_on_tags", using: :gin
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "promotional_banners", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "button_text"
    t.string "link_url"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean "active", default: true
    t.integer "position", default: 0
    t.string "background_color", default: "#F3F4F6"
    t.string "text_color", default: "#111827"
    t.string "button_color", default: "#4F46E5"
    t.string "button_text_color", default: "#FFFFFF"
    t.string "location", default: "home"
    t.bigint "shop_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_category_id"], name: "index_promotional_banners_on_shop_category_id"
  end

  create_table "recent_locations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "address", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.string "location_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_recent_locations_on_user_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_regions_on_code", unique: true
    t.index ["name"], name: "index_regions_on_name", unique: true
  end

  create_table "resource_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "icon"
    t.integer "resources_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.integer "rating", null: false
    t.text "comment", null: false
    t.boolean "approved", default: false
    t.text "admin_comment"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved"], name: "index_reviews_on_approved"
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["user_id", "product_id"], name: "index_reviews_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "ride_bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "origin", null: false
    t.string "destination", null: false
    t.decimal "origin_latitude", precision: 10, scale: 6
    t.decimal "origin_longitude", precision: 10, scale: 6
    t.decimal "destination_latitude", precision: 10, scale: 6
    t.decimal "destination_longitude", precision: 10, scale: 6
    t.datetime "pickup_time", null: false
    t.datetime "dropoff_time"
    t.string "status_string", default: "pending"
    t.string "ride_type_string"
    t.string "driver_name"
    t.string "driver_phone"
    t.string "vehicle_model"
    t.string "vehicle_color"
    t.string "license_plate"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "payment_method"
    t.string "payment_status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "origin_location_id"
    t.bigint "destination_location_id"
    t.integer "status", default: 0, null: false
    t.integer "ride_type", default: 1, null: false
    t.decimal "distance_km", precision: 8, scale: 2
    t.integer "duration_minutes"
    t.string "driver_id"
    t.string "vehicle_id"
    t.text "notes"
    t.json "metadata"
    t.index ["destination_location_id"], name: "index_ride_bookings_on_destination_location_id"
    t.index ["origin_location_id"], name: "index_ride_bookings_on_origin_location_id"
    t.index ["pickup_time"], name: "index_ride_bookings_on_pickup_time"
    t.index ["ride_type"], name: "index_ride_bookings_on_ride_type"
    t.index ["status"], name: "index_ride_bookings_on_status"
    t.index ["user_id"], name: "index_ride_bookings_on_user_id"
  end

  create_table "routes", force: :cascade do |t|
    t.string "origin", null: false
    t.string "destination", null: false
    t.decimal "distance", precision: 10, scale: 2, null: false
    t.string "transport_type_string"
    t.integer "bookings_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "transport_company_id"
    t.integer "duration_minutes"
    t.decimal "base_price", precision: 10, scale: 2
    t.string "currency", default: "GHS"
    t.boolean "popular", default: false
    t.boolean "active", default: true
    t.json "schedule"
    t.json "amenities"
    t.json "metadata"
    t.integer "transport_type", default: 0
    t.index ["active"], name: "index_routes_on_active"
    t.index ["popular"], name: "index_routes_on_popular"
    t.index ["transport_company_id"], name: "index_routes_on_transport_company_id"
    t.index ["transport_type"], name: "index_routes_on_transport_type"
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
    t.bigint "user_id", null: false
    t.index ["destination_wallet_id"], name: "index_scheduled_transactions_on_destination_wallet_id"
    t.index ["next_occurrence"], name: "index_scheduled_transactions_on_next_occurrence"
    t.index ["source_wallet_id"], name: "index_scheduled_transactions_on_source_wallet_id"
    t.index ["status"], name: "index_scheduled_transactions_on_status"
    t.index ["user_id"], name: "index_scheduled_transactions_on_user_id"
  end

  create_table "school_fee_payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "school_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "student_name", null: false
    t.string "student_id", null: false
    t.string "term", null: false
    t.string "payment_method", null: false
    t.string "status", default: "pending"
    t.string "transaction_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_school_fee_payments_on_school_id"
    t.index ["user_id"], name: "index_school_fee_payments_on_user_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name", null: false
    t.string "location", null: false
    t.string "school_type"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "website"
    t.text "description"
    t.string "logo"
    t.boolean "featured", default: false
    t.integer "payments_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "search_queries", force: :cascade do |t|
    t.string "query", null: false
    t.bigint "user_id"
    t.string "ip_address"
    t.string "user_agent"
    t.integer "results_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["query"], name: "index_search_queries_on_query"
    t.index ["user_id"], name: "index_search_queries_on_user_id"
  end

  create_table "security_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "event_type", default: 0, null: false
    t.integer "severity", default: 0, null: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "loggable_type"
    t.bigint "loggable_id"
    t.jsonb "details", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_security_logs_on_loggable"
    t.index ["severity"], name: "index_security_logs_on_severity"
    t.index ["user_id", "created_at"], name: "index_security_logs_on_user_id_and_created_at"
    t.index ["user_id", "event_type"], name: "index_security_logs_on_user_id_and_event_type"
    t.index ["user_id"], name: "index_security_logs_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "shop_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "slug", null: false
    t.string "icon"
    t.string "color_code"
    t.bigint "parent_id"
    t.boolean "featured", default: false
    t.boolean "active", default: true
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shop_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_shop_categories_on_parent_id"
    t.index ["slug"], name: "index_shop_categories_on_slug", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "events_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "ticket_bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "route_id", null: false
    t.string "company_name"
    t.string "transport_type_string", null: false
    t.datetime "departure_time", null: false
    t.datetime "arrival_time", null: false
    t.integer "passengers", default: 1
    t.string "status_string", default: "confirmed"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "payment_method"
    t.string "payment_status", default: "paid"
    t.string "ticket_number"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "transport_company_id"
    t.string "booking_reference"
    t.integer "status", default: 0, null: false
    t.integer "transport_type", default: 0, null: false
    t.string "seat_numbers"
    t.json "amenities"
    t.json "metadata"
    t.index ["booking_reference"], name: "index_ticket_bookings_on_booking_reference", unique: true
    t.index ["departure_time"], name: "index_ticket_bookings_on_departure_time"
    t.index ["route_id"], name: "index_ticket_bookings_on_route_id"
    t.index ["status"], name: "index_ticket_bookings_on_status"
    t.index ["transport_company_id"], name: "index_ticket_bookings_on_transport_company_id"
    t.index ["transport_type"], name: "index_ticket_bookings_on_transport_type"
    t.index ["user_id"], name: "index_ticket_bookings_on_user_id"
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

  create_table "transaction_fees", force: :cascade do |t|
    t.string "name", null: false
    t.integer "transaction_type", default: 4, null: false
    t.integer "fee_type", default: 0, null: false
    t.decimal "fixed_amount", precision: 10, scale: 2
    t.decimal "percentage", precision: 5, scale: 2
    t.decimal "min_fee", precision: 10, scale: 2
    t.decimal "max_fee", precision: 10, scale: 2
    t.boolean "active", default: true
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_transaction_fees_on_active"
    t.index ["transaction_type"], name: "index_transaction_fees_on_transaction_type"
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
    t.bigint "scheduled_transaction_id"
    t.index ["destination_wallet_id"], name: "index_transactions_on_destination_wallet_id"
    t.index ["initiated_at"], name: "index_transactions_on_initiated_at"
    t.index ["payment_method"], name: "index_transactions_on_payment_method"
    t.index ["provider"], name: "index_transactions_on_provider"
    t.index ["scheduled_transaction_id"], name: "index_transactions_on_scheduled_transaction_id"
    t.index ["source_wallet_id"], name: "index_transactions_on_source_wallet_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["transaction_id"], name: "index_transactions_on_transaction_id", unique: true
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "transport_companies", force: :cascade do |t|
    t.string "name", null: false
    t.integer "transport_type", default: 0, null: false
    t.string "logo_url"
    t.string "website"
    t.string "phone"
    t.string "email"
    t.text "description"
    t.boolean "active", default: true
    t.json "amenities"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_transport_companies_on_active"
    t.index ["name"], name: "index_transport_companies_on_name", unique: true
    t.index ["transport_type"], name: "index_transport_companies_on_transport_type"
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
    t.integer "text_size", default: 3
    t.boolean "reduce_motion", default: false
    t.boolean "high_contrast", default: false
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
    t.string "phone"
    t.datetime "phone_verified_at"
    t.integer "kyc_level", default: 0
    t.integer "status", default: 0
    t.string "pin_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.boolean "admin", default: false
    t.boolean "super_admin", default: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.text "bio"
    t.date "date_of_birth"
    t.string "gender"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "postal_code"
    t.string "website"
    t.string "occupation"
    t.boolean "seller", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "((phone IS NOT NULL) AND ((phone)::text <> ''::text))"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["seller"], name: "index_users_on_seller"
    t.index ["super_admin"], name: "index_users_on_super_admin"
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

  create_table "weather_forecasts", force: :cascade do |t|
    t.bigint "region_id", null: false
    t.date "forecast_date", null: false
    t.decimal "temperature_high", precision: 5, scale: 2, null: false
    t.decimal "temperature_low", precision: 5, scale: 2, null: false
    t.decimal "precipitation_chance", precision: 5, scale: 2, null: false
    t.decimal "precipitation_amount", precision: 5, scale: 2, null: false
    t.integer "weather_condition", default: 0
    t.decimal "wind_speed", precision: 5, scale: 2
    t.string "wind_direction"
    t.decimal "humidity", precision: 5, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id", "forecast_date"], name: "index_weather_forecasts_on_region_id_and_forecast_date", unique: true
    t.index ["region_id"], name: "index_weather_forecasts_on_region_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agriculture_resources", "crops"
  add_foreign_key "agriculture_resources", "users"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "beneficiaries", "users"
  add_foreign_key "bill_payments", "transactions"
  add_foreign_key "bill_payments", "users"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "coupons", "shop_categories"
  add_foreign_key "credit_improvement_plans", "users"
  add_foreign_key "credit_improvement_steps", "credit_improvement_plans"
  add_foreign_key "credit_scores", "users"
  add_foreign_key "crop_listing_inquiries", "crop_listings"
  add_foreign_key "crop_listing_inquiries", "users"
  add_foreign_key "crop_listings", "crops"
  add_foreign_key "crop_listings", "regions"
  add_foreign_key "crop_listings", "users"
  add_foreign_key "crop_prices", "crops"
  add_foreign_key "crop_prices", "regions"
  add_foreign_key "digital_downloads", "order_items"
  add_foreign_key "digital_downloads", "products"
  add_foreign_key "digital_downloads", "users"
  add_foreign_key "discounts", "products"
  add_foreign_key "discounts", "shop_categories"
  add_foreign_key "event_categories", "event_categories", column: "parent_category_id"
  add_foreign_key "event_comments", "event_comments", column: "parent_comment_id"
  add_foreign_key "event_comments", "events"
  add_foreign_key "event_comments", "users"
  add_foreign_key "event_favorites", "events"
  add_foreign_key "event_favorites", "users"
  add_foreign_key "event_media", "events"
  add_foreign_key "event_media", "users"
  add_foreign_key "event_tags", "events"
  add_foreign_key "event_tags", "tags"
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
  add_foreign_key "flash_sale_items", "flash_sales"
  add_foreign_key "flash_sale_items", "products"
  add_foreign_key "gathering_attendances", "gatherings"
  add_foreign_key "gathering_attendances", "users"
  add_foreign_key "gatherings", "groups"
  add_foreign_key "gatherings", "users", column: "organizer_id"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "group_categories"
  add_foreign_key "learning_resources", "resource_categories"
  add_foreign_key "loan_refinancings", "loans", column: "new_loan_id"
  add_foreign_key "loan_refinancings", "loans", column: "original_loan_id"
  add_foreign_key "loan_refinancings", "users"
  add_foreign_key "loan_repayments", "loans"
  add_foreign_key "loan_repayments", "transactions"
  add_foreign_key "loans", "loans", column: "refinanced_from_loan_id"
  add_foreign_key "loans", "loans", column: "refinanced_to_loan_id"
  add_foreign_key "loans", "users"
  add_foreign_key "navigation_items", "navigation_items", column: "parent_id"
  add_foreign_key "notification_channels", "users"
  add_foreign_key "notification_deliveries", "notification_channels"
  add_foreign_key "notification_deliveries", "notifications"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "coupons"
  add_foreign_key "orders", "transactions"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "products", "shop_categories"
  add_foreign_key "products", "users"
  add_foreign_key "promotional_banners", "shop_categories"
  add_foreign_key "recent_locations", "users"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "ride_bookings", "recent_locations", column: "destination_location_id"
  add_foreign_key "ride_bookings", "recent_locations", column: "origin_location_id"
  add_foreign_key "ride_bookings", "users"
  add_foreign_key "routes", "transport_companies"
  add_foreign_key "scheduled_transactions", "users"
  add_foreign_key "scheduled_transactions", "wallets", column: "destination_wallet_id"
  add_foreign_key "scheduled_transactions", "wallets", column: "source_wallet_id"
  add_foreign_key "school_fee_payments", "schools"
  add_foreign_key "school_fee_payments", "users"
  add_foreign_key "search_queries", "users"
  add_foreign_key "security_logs", "users"
  add_foreign_key "shop_categories", "shop_categories", column: "parent_id"
  add_foreign_key "ticket_bookings", "routes"
  add_foreign_key "ticket_bookings", "transport_companies"
  add_foreign_key "ticket_bookings", "users"
  add_foreign_key "ticket_types", "events"
  add_foreign_key "transactions", "scheduled_transactions"
  add_foreign_key "transactions", "wallets", column: "destination_wallet_id"
  add_foreign_key "transactions", "wallets", column: "source_wallet_id"
  add_foreign_key "user_settings", "users"
  add_foreign_key "venues", "users"
  add_foreign_key "wallets", "users"
  add_foreign_key "weather_forecasts", "regions"
end
