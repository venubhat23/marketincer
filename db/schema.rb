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

ActiveRecord::Schema[8.0].define(version: 2025_01_01_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_generation_logs", force: :cascade do |t|
    t.bigint "contract_id"
    t.text "description", null: false
    t.text "generated_content"
    t.integer "status", default: 0
    t.text "error_message"
    t.json "ai_response_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_ai_generation_logs_on_contract_id"
    t.index ["created_at"], name: "index_ai_generation_logs_on_created_at"
    t.index ["status"], name: "index_ai_generation_logs_on_status"
  end

  create_table "bids", force: :cascade do |t|
    t.bigint "marketplace_post_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_bids_on_created_at"
    t.index ["marketplace_post_id", "user_id"], name: "index_bids_on_marketplace_post_id_and_user_id", unique: true
    t.index ["marketplace_post_id"], name: "index_bids_on_marketplace_post_id"
    t.index ["status"], name: "index_bids_on_status"
    t.index ["user_id"], name: "index_bids_on_user_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "contract_type", default: 0
    t.integer "status", default: 0
    t.integer "category", default: 0
    t.date "date_created"
    t.string "action", default: "pending"
    t.text "content"
    t.text "description"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_contracts_on_category"
    t.index ["contract_type"], name: "index_contracts_on_contract_type"
    t.index ["date_created"], name: "index_contracts_on_date_created"
    t.index ["name"], name: "index_contracts_on_name"
    t.index ["status"], name: "index_contracts_on_status"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "company_name"
    t.string "gst_number"
    t.string "phone_number"
    t.text "address"
    t.string "company_website"
    t.string "job_title"
    t.string "work_email"
    t.decimal "gst_percentage"
    t.jsonb "line_items"
    t.decimal "total_amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "due_date"
    t.string "customer"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "marketplace_posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "category"
    t.string "target_audience"
    t.decimal "budget", precision: 10, scale: 2
    t.string "location"
    t.string "platform"
    t.string "languages"
    t.date "deadline"
    t.string "tags"
    t.string "status", default: "draft"
    t.string "brand_name"
    t.string "media_url"
    t.string "media_type"
    t.integer "views_count", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_marketplace_posts_on_category"
    t.index ["created_at"], name: "index_marketplace_posts_on_created_at"
    t.index ["deadline"], name: "index_marketplace_posts_on_deadline"
    t.index ["status"], name: "index_marketplace_posts_on_status"
    t.index ["user_id"], name: "index_marketplace_posts_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "s3_url"
    t.string "status"
    t.string "hashtags"
    t.text "note"
    t.text "comments"
    t.string "brand_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "social_page_id"
    t.text "publish_log"
    t.datetime "scheduled_at"
    t.bigint "account_id"
    t.index ["social_page_id"], name: "index_posts_on_social_page_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "company_name"
    t.string "gst_number"
    t.string "phone_number"
    t.string "address"
    t.string "company_website"
    t.string "job_title"
    t.string "work_email"
    t.decimal "gst_percentage"
    t.string "status"
    t.decimal "total_amount"
    t.string "order_number"
    t.jsonb "line_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer"
    t.index ["user_id"], name: "index_purchase_orders_on_user_id"
  end

  create_table "social_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider"
    t.string "access_token"
    t.json "user_info"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_social_accounts_on_user_id"
  end

  create_table "social_pages", force: :cascade do |t|
    t.bigint "social_account_id", null: false
    t.string "name"
    t.string "username"
    t.string "page_type"
    t.string "social_id"
    t.string "page_id"
    t.string "picture_url"
    t.string "access_token"
    t.boolean "connected", default: false
    t.json "page_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_page", default: false
    t.index ["social_account_id"], name: "index_social_pages_on_social_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "activation_token"
    t.boolean "activated", default: false
    t.datetime "activation_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "brand", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "gst_name"
    t.string "gst_number"
    t.string "phone_number"
    t.text "address"
    t.string "company_website"
    t.string "job_title"
    t.string "work_email"
    t.decimal "gst_percentage", precision: 5, scale: 2, default: "18.0"
    t.index ["activation_token"], name: "index_users_on_activation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "ai_generation_logs", "contracts"
  add_foreign_key "bids", "marketplace_posts"
  add_foreign_key "bids", "users"
  add_foreign_key "invoices", "users"
  add_foreign_key "marketplace_posts", "users"
  add_foreign_key "posts", "social_pages"
  add_foreign_key "posts", "users"
  add_foreign_key "purchase_orders", "users"
  add_foreign_key "social_accounts", "users"
  add_foreign_key "social_pages", "social_accounts"
end
