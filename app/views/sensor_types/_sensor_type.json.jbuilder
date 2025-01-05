json.extract! sensor_type, :id, :name, :min_temp, :max_temp, :min_humidity, :max_humidity, :accuracy_temp, :resolution_temp, :accuracy_humidity, :resolution_humidity, :created_at, :updated_at
json.url sensor_type_url(sensor_type, format: :json)
