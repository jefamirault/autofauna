json.extract! tds_reading, :id, :datetime, :zone_id, :tds, :sensor_id, :created_at, :updated_at
json.url tds_reading_url(tds_reading, format: :json)
