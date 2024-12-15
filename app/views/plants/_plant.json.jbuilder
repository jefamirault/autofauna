json.extract! plant,  :id,
                      :name,
                      :uid,
                      :location,
                      :container,
                      :min_watering_freq,
                      :max_watering_freq,
                      :date_scheduled_watering,
                      :date_last_watering,
                      :archived,
                      :created_at,
                      :updated_at
json.url plant_url(plant, format: :json)
