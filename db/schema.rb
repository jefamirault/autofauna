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

ActiveRecord::Schema[8.0].define(version: 2026_07_30_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "collaborations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.integer "role"
  end

  create_table "equipment", force: :cascade do |t|
    t.bigint "tank_id", null: false
    t.string "name"
    t.text "maintenance_instructions"
    t.integer "maintenance_interval_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tank_id"], name: "index_equipment_on_tank_id"
  end

  create_table "feeding_instructions", force: :cascade do |t|
    t.bigint "tank_id", null: false
    t.string "food_name"
    t.string "amount"
    t.string "unit"
    t.string "frequency"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tank_id"], name: "index_feeding_instructions_on_tank_id"
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

  create_table "location_supplies", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.string "supplyable_type", null: false
    t.bigint "supplyable_id", null: false
    t.float "quantity", default: 0.0, null: false
    t.integer "quantity_units"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "supplyable_type", "supplyable_id"], name: "index_location_supplies_on_location_and_supplyable", unique: true
    t.index ["location_id"], name: "index_location_supplies_on_location_id"
    t.index ["supplyable_type", "supplyable_id"], name: "index_location_supplies_on_supplyable"
  end

  create_table "location_supply_adjustments", force: :cascade do |t|
    t.bigint "location_supply_id", null: false
    t.bigint "user_id"
    t.integer "action", null: false
    t.float "amount", default: 0.0, null: false
    t.integer "units"
    t.float "quantity_after"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_supply_id"], name: "index_location_supply_adjustments_on_location_supply_id"
    t.index ["user_id"], name: "index_location_supply_adjustments_on_user_id"
  end

  create_table "locations", force: :cascade do |t|
    t.integer "zone_id"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_id"
    t.string "color", default: "#0E487B"
  end

  create_table "log_entries", force: :cascade do |t|
    t.string "entry_type"
    t.text "description"
    t.string "loggable_type", null: false
    t.bigint "loggable_id", null: false
    t.bigint "user_id"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_log_entries_on_loggable"
    t.index ["user_id"], name: "index_log_entries_on_user_id"
  end

  create_table "maintenance_logs", force: :cascade do |t|
    t.bigint "equipment_id", null: false
    t.datetime "performed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_id"], name: "index_maintenance_logs_on_equipment_id"
    t.index ["performed_at"], name: "index_maintenance_logs_on_performed_at"
  end

  create_table "notification_configs", force: :cascade do |t|
    t.string "cron_expression", default: "0 * * * *", null: false
    t.boolean "notifications_paused", default: false, null: false
    t.string "email_subject_template", default: "{{count}} plant(s) need watering", null: false
    t.text "email_body_template", null: false
    t.string "push_title_template", default: "Water {{plant_name}}", null: false
    t.string "push_body_template", default: "{{plant_label}} is due for watering", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plant_group_memberships", force: :cascade do |t|
    t.bigint "plant_id", null: false
    t.bigint "plant_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_group_id"], name: "index_plant_group_memberships_on_plant_group_id"
    t.index ["plant_id", "plant_group_id"], name: "index_plant_group_memberships_on_plant_and_group", unique: true
    t.index ["plant_id"], name: "index_plant_group_memberships_on_plant_id"
  end

  create_table "plant_groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#0E487B"
    t.bigint "project_id", null: false
    t.integer "min_watering_freq"
    t.integer "max_watering_freq"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_plant_groups_on_project_id"
  end

  create_table "plant_recipes", force: :cascade do |t|
    t.bigint "plant_id", null: false
    t.bigint "recipe_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_id", "recipe_id"], name: "index_plant_recipes_on_plant_id_and_recipe_id", unique: true
    t.index ["plant_id"], name: "index_plant_recipes_on_plant_id"
    t.index ["recipe_id"], name: "index_plant_recipes_on_recipe_id"
  end

  create_table "plants", force: :cascade do |t|
    t.string "name"
    t.integer "uid"
    t.string "pot"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "project_id"
    t.integer "min_watering_freq"
    t.integer "max_watering_freq"
    t.date "date_last_watering"
    t.integer "last_watering_id"
    t.date "date_min_watering"
    t.date "date_max_watering"
    t.date "date_sort_watering"
    t.integer "zone_id"
    t.bigint "location_id"
    t.string "graphic"
    t.string "share_token"
    t.boolean "share_enabled", default: false
    t.bigint "recipe_id"
    t.string "view_share_token"
    t.boolean "view_share_enabled", default: false
    t.datetime "snoozed_until"
    t.float "layout_x"
    t.float "layout_y"
    t.index ["last_watering_id"], name: "index_plants_on_last_watering_id"
    t.index ["location_id"], name: "index_plants_on_location_id"
    t.index ["recipe_id"], name: "index_plants_on_recipe_id"
    t.index ["share_token"], name: "index_plants_on_share_token", unique: true
    t.index ["view_share_token"], name: "index_plants_on_view_share_token", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.integer "owner_id"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_key"
    t.integer "moisture_measurement_type", default: 0, null: false
    t.index ["moisture_measurement_type"], name: "index_projects_on_moisture_measurement_type"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false
    t.string "p256dh_key", null: false
    t.string "auth_key", null: false
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true, null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "recipe_batches", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "recipe_id", null: false
    t.integer "tds"
    t.float "volume"
    t.integer "volume_units"
    t.date "mixed_on"
    t.text "notes"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "remaining_volume"
    t.datetime "last_adjusted_at"
    t.index ["project_id"], name: "index_recipe_batches_on_project_id"
    t.index ["recipe_id"], name: "index_recipe_batches_on_recipe_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "recipe_source_id", null: false
    t.decimal "amount", precision: 10, scale: 4
    t.string "units"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "recipe_source_id"], name: "index_recipe_ingredients_on_recipe_id_and_recipe_source_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
    t.index ["recipe_source_id"], name: "index_recipe_ingredients_on_recipe_source_id"
  end

  create_table "recipe_sources", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.bigint "tank_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pinned", default: false, null: false
    t.index ["project_id", "name"], name: "index_recipe_sources_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_recipe_sources_on_project_id"
    t.index ["tank_id"], name: "index_recipe_sources_on_tank_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color", default: "#7B1FA2"
    t.integer "default_tds"
    t.boolean "pinned", default: false, null: false
    t.index ["project_id", "name"], name: "index_recipes_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_recipes_on_project_id"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.string "query_term", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "filter_params"
    t.index ["user_id", "project_id"], name: "index_saved_searches_on_user_id_and_project_id"
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
    t.integer "project_id"
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

  create_table "soil_moisture_readings", force: :cascade do |t|
    t.bigint "plant_id", null: false
    t.bigint "watering_id"
    t.datetime "measured_at", null: false
    t.decimal "value_numeric", precision: 5, scale: 2
    t.integer "value_categorical"
    t.integer "timing", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["measured_at"], name: "index_soil_moisture_readings_on_measured_at"
    t.index ["plant_id", "measured_at"], name: "index_soil_moisture_readings_on_plant_id_and_measured_at"
    t.index ["plant_id"], name: "index_soil_moisture_readings_on_plant_id"
    t.index ["timing"], name: "index_soil_moisture_readings_on_timing"
    t.index ["watering_id"], name: "index_soil_moisture_readings_on_watering_id"
  end

  create_table "tanks", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "capacity"
    t.integer "capacity_units"
    t.integer "project_id"
    t.integer "location_id"
    t.integer "water_change_min_days"
    t.integer "water_change_max_days"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "advanced_mode", default: false
    t.boolean "login_enabled", default: true, null: false
    t.boolean "guest", default: false, null: false
    t.string "google_uid"
    t.string "avatar_url"
    t.boolean "email_notifications_enabled", default: true, null: false
    t.boolean "push_notifications_enabled", default: true, null: false
    t.time "email_notification_time", default: "2000-01-01 09:00:00"
    t.time "push_notification_time", default: "2000-01-01 09:00:00"
    t.string "email_notification_frequency_type", default: "daily"
    t.integer "email_notification_frequency_value", default: 1
    t.string "push_notification_frequency_type", default: "daily"
    t.integer "push_notification_frequency_value", default: 1
    t.datetime "last_email_notification_sent_at"
    t.datetime "last_push_notification_sent_at"
    t.boolean "track_waterings", default: true, null: false
    t.boolean "use_fertilizers", default: true, null: false
    t.boolean "precise_measurements", default: true, null: false
    t.boolean "track_soil_moisture", default: true, null: false
    t.boolean "has_aquarium", default: true, null: false
    t.datetime "onboarding_completed_at"
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  create_table "water_changes", force: :cascade do |t|
    t.bigint "tank_id", null: false
    t.datetime "changed_at"
    t.float "percentage"
    t.float "volume"
    t.integer "volume_units"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["changed_at"], name: "index_water_changes_on_changed_at"
    t.index ["tank_id"], name: "index_water_changes_on_tank_id"
  end

  create_table "water_tests", force: :cascade do |t|
    t.bigint "tank_id", null: false
    t.jsonb "parameters", default: {}, null: false
    t.datetime "tested_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parameters"], name: "index_water_tests_on_parameters", using: :gin
    t.index ["tank_id"], name: "index_water_tests_on_tank_id"
    t.index ["tested_at"], name: "index_water_tests_on_tested_at"
  end

  create_table "waterings", force: :cascade do |t|
    t.integer "plant_id"
    t.datetime "watered_at"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "interval"
    t.float "volume"
    t.integer "units"
    t.integer "tds"
    t.bigint "recipe_batch_id"
    t.bigint "recipe_id"
    t.bigint "recipe_source_id"
    t.index ["recipe_batch_id"], name: "index_waterings_on_recipe_batch_id"
    t.index ["recipe_id"], name: "index_waterings_on_recipe_id"
    t.index ["recipe_source_id"], name: "index_waterings_on_recipe_source_id"
  end

  create_table "weather_locations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.decimal "latitude", precision: 9, scale: 4, null: false
    t.decimal "longitude", precision: 9, scale: 4, null: false
    t.string "zip"
    t.string "location_name"
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "primary"], name: "index_weather_locations_on_user_id_and_primary"
    t.index ["user_id"], name: "index_weather_locations_on_user_id"
  end

  create_table "zones", force: :cascade do |t|
    t.string "name"
    t.integer "project_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "equipment", "tanks"
  add_foreign_key "feeding_instructions", "tanks"
  add_foreign_key "location_supplies", "locations"
  add_foreign_key "location_supply_adjustments", "location_supplies"
  add_foreign_key "log_entries", "users", on_delete: :nullify
  add_foreign_key "maintenance_logs", "equipment"
  add_foreign_key "plant_group_memberships", "plant_groups"
  add_foreign_key "plant_group_memberships", "plants"
  add_foreign_key "plant_groups", "projects"
  add_foreign_key "plant_recipes", "plants"
  add_foreign_key "plant_recipes", "recipes"
  add_foreign_key "plants", "locations"
  add_foreign_key "plants", "recipes"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "recipe_batches", "projects"
  add_foreign_key "recipe_batches", "recipes"
  add_foreign_key "recipe_ingredients", "recipe_sources"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipe_sources", "projects"
  add_foreign_key "recipe_sources", "tanks"
  add_foreign_key "recipes", "projects"
  add_foreign_key "saved_searches", "projects"
  add_foreign_key "saved_searches", "users"
  add_foreign_key "soil_moisture_readings", "plants"
  add_foreign_key "soil_moisture_readings", "waterings"
  add_foreign_key "water_changes", "tanks"
  add_foreign_key "water_tests", "tanks"
  add_foreign_key "waterings", "recipe_batches"
  add_foreign_key "waterings", "recipe_sources"
  add_foreign_key "waterings", "recipes"
  add_foreign_key "weather_locations", "users"
end
