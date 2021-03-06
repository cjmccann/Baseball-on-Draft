# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170325060509) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "data_managers", force: :cascade do |t|
    t.integer  "draft_helper_id"
    t.integer  "league_id"
    t.integer  "user_id"
    t.text     "averages"
    t.text     "stddevs"
    t.text     "positional_adjustments"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.text     "means"
    t.text     "current_percentiles"
    t.text     "initial_percentiles"
  end

  create_table "draft_helpers", force: :cascade do |t|
    t.integer  "league_id"
    t.integer  "user_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "data_manager_id"
    t.text     "drafted_player_ids"
    t.text     "drafted_player_ids_by_team"
  end

  add_index "draft_helpers", ["league_id"], name: "index_draft_helpers_on_league_id", using: :btree

  create_table "leagues", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "user_id"
    t.integer  "setting_manager_id"
  end

  add_index "leagues", ["setting_manager_id"], name: "index_leagues_on_setting_manager_id", using: :btree

  create_table "players", force: :cascade do |t|
    t.string   "name"
    t.string   "position"
    t.string   "player_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.text     "static_stats"
  end

  add_index "players", ["name", "player_type"], name: "index_players_on_name_and_player_type", using: :btree

  create_table "setting_managers", force: :cascade do |t|
    t.integer  "league_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "user_id"
    t.integer  "bat_C"
    t.integer  "bat_1B"
    t.integer  "bat_2B"
    t.integer  "bat_3B"
    t.integer  "bat_SS"
    t.integer  "bat_LF"
    t.integer  "bat_CF"
    t.integer  "bat_RF"
    t.integer  "bat_CI"
    t.integer  "bat_MI"
    t.integer  "bat_OF"
    t.integer  "bat_UTIL"
    t.integer  "pit_SP"
    t.integer  "pit_RP"
    t.integer  "pit_P"
    t.boolean  "bat_r"
    t.boolean  "bat_hr"
    t.boolean  "bat_rbi"
    t.boolean  "bat_sb"
    t.boolean  "bat_obp"
    t.boolean  "bat_slg"
    t.boolean  "bat_doubles"
    t.boolean  "bat_bb"
    t.boolean  "bat_so"
    t.boolean  "bat_avg"
    t.boolean  "bat_war"
    t.boolean  "pit_sv"
    t.boolean  "pit_hr"
    t.boolean  "pit_so"
    t.boolean  "pit_era"
    t.boolean  "pit_whip"
    t.boolean  "pit_qs"
    t.boolean  "pit_gs"
    t.boolean  "pit_w"
    t.boolean  "pit_l"
    t.boolean  "pit_h"
    t.boolean  "pit_bb"
    t.boolean  "pit_kper9"
    t.boolean  "pit_bbper9"
    t.boolean  "pit_fip"
    t.boolean  "pit_war"
    t.boolean  "pit_dra"
    t.integer  "num_teams"
    t.boolean  "pit_hld"
    t.boolean  "bat_ops"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "league_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "user_id"
    t.text     "batters"
    t.text     "pitchers"
    t.text     "batter_slots"
    t.text     "pitcher_slots"
    t.text     "team_percentiles"
    t.text     "team_raw_stats"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
