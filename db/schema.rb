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

ActiveRecord::Schema[8.0].define(version: 2025_01_04_163358) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "collaborations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.integer "role"
  end

  create_table "hygro_sensor_readings", force: :cascade do |t|
    t.datetime "datetime"
    t.integer "temperature"
    t.integer "humidity"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sensor_id"
    t.string "error"
  end

  create_table "plants", force: :cascade do |t|
    t.string "name"
    t.integer "uid"
    t.string "location"
    t.string "pot"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.date "date_scheduled_watering"
    t.integer "project_id"
    t.integer "min_watering_freq"
    t.integer "max_watering_freq"
    t.integer "scheduled_watering_id"
    t.date "date_last_watering"
    t.integer "last_watering_id"
    t.date "date_min_watering"
    t.date "date_max_watering"
    t.date "date_sort_watering"
    t.integer "zone_id"
    t.index ["last_watering_id"], name: "index_plants_on_last_watering_id"
    t.index ["scheduled_watering_id"], name: "index_plants_on_scheduled_watering_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "owner_id"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_key"
  end

  create_table "sensor_types", force: :cascade do |t|
    t.string "name"
    t.integer "min_temp"
    t.integer "max_temp"
    t.integer "min_humidity"
    t.integer "max_humidity"
    t.float "accuracy_temp"
    t.float "resolution_temp"
    t.float "accuracy_humidity"
    t.float "resolution_humidity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sensors", force: :cascade do |t|
    t.string "name"
    t.integer "zone_id"
    t.string "location"
    t.integer "project_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sensor_type_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "waterings", force: :cascade do |t|
    t.integer "plant_id"
    t.date "date"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "interval"
    t.boolean "fulfilled", default: true, null: false
  end

  create_table "zones", force: :cascade do |t|
    t.string "name"
    t.integer "project_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
