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

ActiveRecord::Schema[8.0].define(version: 2025_05_01_110911) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "invoices", "users"
  add_foreign_key "posts", "social_pages"
  add_foreign_key "posts", "users"
  add_foreign_key "purchase_orders", "users"
  add_foreign_key "social_accounts", "users"
  add_foreign_key "social_pages", "social_accounts"
end
