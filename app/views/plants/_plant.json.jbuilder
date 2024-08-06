json.extract! plant, :id, :name, :uid, :location, :pot, :scheduled_watering, :archived, :created_at, :updated_at
json.url plant_url(plant, format: :json)
