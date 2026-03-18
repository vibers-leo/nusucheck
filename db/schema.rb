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

ActiveRecord::Schema[7.1].define(version: 2026_03_18_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "coupons", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.string "coupon_type", null: false
    t.decimal "discount_value", precision: 10, scale: 2, null: false
    t.decimal "min_amount", precision: 10, scale: 2
    t.decimal "max_discount", precision: 10, scale: 2
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.integer "usage_limit"
    t.integer "usage_count", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
  end

  create_table "email_subscriptions", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "subscribed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_subscriptions_on_email", unique: true
  end

  create_table "escrow_transactions", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "master_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "platform_fee", precision: 10, scale: 2, default: "0.0"
    t.decimal "master_payout", precision: 10, scale: 2, default: "0.0"
    t.string "payment_method"
    t.string "pg_transaction_id"
    t.string "escrow_type", default: "construction", null: false
    t.string "status", default: "pending"
    t.datetime "deposited_at"
    t.datetime "released_at"
    t.datetime "refunded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "toss_order_id"
    t.string "toss_payment_key"
    t.index ["customer_id"], name: "index_escrow_transactions_on_customer_id"
    t.index ["master_id"], name: "index_escrow_transactions_on_master_id"
    t.index ["request_id", "escrow_type"], name: "index_escrow_transactions_on_request_id_and_type", unique: true
    t.index ["toss_order_id"], name: "index_escrow_transactions_on_toss_order_id", unique: true, where: "(toss_order_id IS NOT NULL)"
  end

  create_table "estimates", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "master_id", null: false
    t.jsonb "line_items", default: []
    t.decimal "detection_subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "construction_subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "material_subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "vat", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.string "status", default: "pending"
    t.text "notes"
    t.datetime "valid_until"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_estimates_on_master_id"
    t.index ["request_id"], name: "index_estimates_on_request_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "category"
    t.text "message"
    t.string "status", default: "pending"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_feedbacks_on_created_at"
    t.index ["status"], name: "index_feedbacks_on_status"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "insurance_claims", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "request_id"
    t.string "status", default: "draft", null: false
    t.string "applicant_name", null: false
    t.string "applicant_phone", null: false
    t.string "applicant_email"
    t.date "birth_date"
    t.text "incident_address", null: false
    t.string "incident_detail_address"
    t.date "incident_date", null: false
    t.text "incident_description", null: false
    t.string "damage_type"
    t.decimal "estimated_damage_amount", precision: 12, scale: 2
    t.string "insurance_company"
    t.string "policy_number"
    t.string "insurance_type", default: "daily_liability"
    t.string "victim_name"
    t.string "victim_phone"
    t.text "victim_address"
    t.text "admin_notes"
    t.string "claim_number", null: false
    t.datetime "submitted_at"
    t.datetime "reviewed_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "prepared_by_master_id"
    t.boolean "customer_reviewed", default: false
    t.text "customer_review_notes"
    t.datetime "customer_reviewed_at"
    t.index ["claim_number"], name: "index_insurance_claims_on_claim_number", unique: true
    t.index ["customer_id"], name: "index_insurance_claims_on_customer_id"
    t.index ["prepared_by_master_id"], name: "index_insurance_claims_on_prepared_by_master_id"
    t.index ["request_id"], name: "index_insurance_claims_on_request_id"
    t.index ["status"], name: "index_insurance_claims_on_status"
  end

  create_table "leak_inspections", force: :cascade do |t|
    t.bigint "customer_id"
    t.string "status", default: "pending", null: false
    t.boolean "leak_detected", default: false
    t.string "severity"
    t.text "analysis_summary"
    t.jsonb "analysis_detail", default: {}
    t.text "recommended_action"
    t.string "location_description"
    t.integer "symptom_type"
    t.string "ai_model_used"
    t.integer "ai_tokens_used", default: 0
    t.float "analysis_duration_seconds"
    t.string "session_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_leak_inspections_on_customer_id"
    t.index ["session_token"], name: "index_leak_inspections_on_session_token", unique: true
    t.index ["status"], name: "index_leak_inspections_on_status"
  end

  create_table "master_applications", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "master_id", null: false
    t.text "intro_message"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_master_applications_on_master_id"
    t.index ["request_id", "master_id"], name: "index_master_applications_on_request_id_and_master_id", unique: true
    t.index ["request_id"], name: "index_master_applications_on_request_id"
  end

  create_table "master_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "license_number"
    t.string "license_type"
    t.jsonb "equipment", default: []
    t.text "service_areas", default: [], array: true
    t.integer "experience_years", default: 0
    t.string "bank_name"
    t.string "account_number"
    t.string "account_holder"
    t.boolean "verified", default: false
    t.datetime "verified_at"
    t.text "bio"
    t.text "specialty_types", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["specialty_types"], name: "index_master_profiles_on_specialty_types", using: :gin
    t.index ["user_id"], name: "index_master_profiles_on_user_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "sender_id"
    t.text "content", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "message_type", default: 0, null: false
    t.integer "message_category", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.index ["message_category"], name: "index_messages_on_message_category"
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["metadata"], name: "index_messages_on_metadata", using: :gin
    t.index ["request_id", "created_at"], name: "index_messages_on_request_id_and_created_at"
    t.index ["request_id"], name: "index_messages_on_request_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.string "actor_type"
    t.bigint "actor_id"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.string "action", null: false
    t.text "message"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_notifications_on_actor"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_type", "recipient_id", "created_at"], name: "idx_on_recipient_type_recipient_id_created_at_b03107666b"
    t.index ["recipient_type", "recipient_id", "read_at"], name: "idx_on_recipient_type_recipient_id_read_at_50191a301d"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient"
  end

  create_table "payment_audit_logs", force: :cascade do |t|
    t.bigint "escrow_transaction_id"
    t.bigint "user_id"
    t.string "action", null: false
    t.jsonb "details", default: {}
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_payment_audit_logs_on_action"
    t.index ["created_at"], name: "index_payment_audit_logs_on_created_at"
    t.index ["escrow_transaction_id"], name: "index_payment_audit_logs_on_escrow_transaction_id"
    t.index ["user_id", "created_at"], name: "index_payment_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_payment_audit_logs_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.string "category", default: "general", null: false
    t.integer "views_count", default: 0, null: false
    t.integer "likes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_posts_on_category"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "master_id"
    t.string "status", default: "reported"
    t.integer "symptom_type", null: false
    t.integer "building_type", default: 0
    t.text "address", null: false
    t.string "detailed_address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "floor_info"
    t.text "description"
    t.datetime "preferred_date"
    t.datetime "assigned_at"
    t.datetime "visit_started_at"
    t.datetime "detection_started_at"
    t.datetime "construction_started_at"
    t.datetime "construction_completed_at"
    t.datetime "closed_at"
    t.integer "detection_result"
    t.text "detection_notes"
    t.decimal "trip_fee", precision: 10, scale: 2, default: "0.0"
    t.decimal "detection_fee", precision: 10, scale: 2, default: "0.0"
    t.decimal "construction_fee", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_fee", precision: 10, scale: 2, default: "0.0"
    t.integer "warranty_period_months", default: 0
    t.datetime "warranty_expires_at"
    t.text "warranty_notes"
    t.text "customer_complaint"
    t.datetime "complaint_submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_requests_on_customer_id"
    t.index ["master_id"], name: "index_requests_on_master_id"
    t.index ["status"], name: "index_requests_on_status"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "master_id", null: false
    t.decimal "overall_rating", precision: 3, scale: 2, null: false
    t.integer "punctuality_rating"
    t.integer "skill_rating"
    t.integer "kindness_rating"
    t.integer "cleanliness_rating"
    t.integer "price_rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_reviews_on_customer_id"
    t.index ["master_id"], name: "index_reviews_on_master_id"
    t.index ["request_id"], name: "index_reviews_on_request_id", unique: true
  end

  create_table "standard_estimate_items", force: :cascade do |t|
    t.string "category", null: false
    t.string "name", null: false
    t.text "description"
    t.string "unit"
    t.decimal "min_price", precision: 10, scale: 2
    t.decimal "max_price", precision: 10, scale: 2
    t.decimal "default_price", precision: 10, scale: 2
    t.text "recommended_for", default: [], array: true
    t.integer "sort_order", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "master_id", null: false
    t.integer "tier", default: 0, null: false
    t.decimal "monthly_fee", precision: 10, scale: 2, default: "0.0"
    t.date "starts_on"
    t.date "expires_on"
    t.boolean "active", default: true
    t.jsonb "features", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscriptions_on_active"
    t.index ["master_id", "active"], name: "index_subscriptions_on_master_id_and_active"
    t.index ["master_id"], name: "index_subscriptions_on_master_id"
    t.index ["tier"], name: "index_subscriptions_on_tier"
  end

  create_table "surveys", force: :cascade do |t|
    t.string "need_app"
    t.text "reason"
    t.string "contact_info"
    t.string "user_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_surveys_on_created_at"
    t.index ["need_app"], name: "index_surveys_on_need_app"
    t.index ["user_id"], name: "index_surveys_on_user_id"
  end

  create_table "user_coupons", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "coupon_id", null: false
    t.boolean "used", default: false
    t.datetime "used_at"
    t.bigint "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_id"], name: "index_user_coupons_on_coupon_id"
    t.index ["request_id"], name: "index_user_coupons_on_request_id"
    t.index ["user_id", "coupon_id"], name: "index_user_coupons_on_user_id_and_coupon_id", unique: true
    t.index ["user_id"], name: "index_user_coupons_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "type"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.string "phone"
    t.text "address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "email_notifications", default: true
    t.boolean "push_notifications", default: true
    t.boolean "sms_notifications", default: false
    t.boolean "estimate_notification", default: true
    t.boolean "construction_notification", default: true
    t.boolean "insurance_notification", default: true
    t.boolean "marketing_notification", default: false
    t.integer "account_status", default: 0, null: false
    t.string "guest_token"
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["guest_token"], name: "index_users_on_guest_token", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["type"], name: "index_users_on_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "escrow_transactions", "requests"
  add_foreign_key "escrow_transactions", "users", column: "customer_id"
  add_foreign_key "escrow_transactions", "users", column: "master_id"
  add_foreign_key "estimates", "requests"
  add_foreign_key "estimates", "users", column: "master_id"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "insurance_claims", "requests"
  add_foreign_key "insurance_claims", "users", column: "customer_id"
  add_foreign_key "insurance_claims", "users", column: "prepared_by_master_id"
  add_foreign_key "leak_inspections", "users", column: "customer_id"
  add_foreign_key "master_applications", "requests"
  add_foreign_key "master_applications", "users", column: "master_id"
  add_foreign_key "master_profiles", "users"
  add_foreign_key "messages", "requests"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "payment_audit_logs", "escrow_transactions"
  add_foreign_key "payment_audit_logs", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "requests", "users", column: "customer_id"
  add_foreign_key "requests", "users", column: "master_id"
  add_foreign_key "reviews", "requests"
  add_foreign_key "reviews", "users", column: "customer_id"
  add_foreign_key "reviews", "users", column: "master_id"
  add_foreign_key "subscriptions", "users", column: "master_id"
  add_foreign_key "surveys", "users"
  add_foreign_key "user_coupons", "coupons"
  add_foreign_key "user_coupons", "requests"
  add_foreign_key "user_coupons", "users"
end
