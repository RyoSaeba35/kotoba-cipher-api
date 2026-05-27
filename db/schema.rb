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

ActiveRecord::Schema[8.1].define(version: 2026_05_27_103446) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "animes", force: :cascade do |t|
    t.string "anime_type"
    t.datetime "created_at", null: false
    t.string "creator"
    t.string "image_url"
    t.string "studio"
    t.string "title"
    t.string "title_japanese"
    t.jsonb "titles", default: {}
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["titles"], name: "index_animes_on_titles", using: :gin
  end

  create_table "authors", force: :cascade do |t|
    t.text "bio"
    t.jsonb "bios", default: {}
    t.datetime "created_at", null: false
    t.string "image_url"
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "wikipedia_url"
    t.index ["bios"], name: "index_authors_on_bios", using: :gin
  end

  create_table "characters", force: :cascade do |t|
    t.bigint "anime_id", null: false
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "image_url"
    t.string "name"
    t.string "name_japanese"
    t.jsonb "names", default: {}
    t.datetime "updated_at", null: false
    t.string "voice_actor"
    t.string "voice_actor_japanese"
    t.index ["anime_id"], name: "index_characters_on_anime_id"
    t.index ["names"], name: "index_characters_on_names", using: :gin
  end

  create_table "puzzles", force: :cascade do |t|
    t.bigint "anime_id", null: false
    t.string "artwork"
    t.bigint "author_id"
    t.bigint "character_id"
    t.jsonb "cipher_mapping", default: {}
    t.jsonb "cipher_mappings_i18n", default: {}
    t.datetime "created_at", null: false
    t.string "default_locale", default: "en"
    t.string "difficulty", default: "medium"
    t.text "encrypted_text"
    t.jsonb "encrypted_texts", default: {}
    t.date "featured_date"
    t.jsonb "hints", default: []
    t.jsonb "hints_i18n", default: {}
    t.integer "points", default: 100
    t.text "solution", null: false
    t.jsonb "solutions", default: {}
    t.jsonb "starting_letters", default: []
    t.jsonb "starting_letters_i18n", default: {}
    t.integer "time_limit"
    t.string "topic"
    t.datetime "updated_at", null: false
    t.integer "video_duration"
    t.string "video_thumbnail_url"
    t.string "video_url"
    t.index ["anime_id"], name: "index_puzzles_on_anime_id"
    t.index ["author_id"], name: "index_puzzles_on_author_id"
    t.index ["character_id"], name: "index_puzzles_on_character_id"
    t.index ["created_at"], name: "index_puzzles_on_created_at"
    t.index ["default_locale"], name: "index_puzzles_on_default_locale"
    t.index ["difficulty"], name: "index_puzzles_on_difficulty"
    t.index ["featured_date"], name: "index_puzzles_on_featured_date"
    t.index ["solutions"], name: "index_puzzles_on_solutions", using: :gin
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  add_foreign_key "characters", "animes"
  add_foreign_key "puzzles", "animes"
  add_foreign_key "puzzles", "authors"
  add_foreign_key "puzzles", "characters"
end
