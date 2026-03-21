class WeatherService
  BASE_URL = "https://api.open-meteo.com/v1/forecast"
  GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1/search"

  def self.fetch(lat:, lon:)
    cache_key = "weather/#{lat.round(2)},#{lon.round(2)}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      fetch_from_api(lat: lat, lon: lon)
    end
  end

  def self.geocode_zip(zip)
    return nil if zip.blank?

    url = URI("#{GEOCODING_URL}?name=#{URI.encode_www_form_component(zip)}&count=1&language=en&format=json")
    response = http_get(url)
    return nil unless response

    data = JSON.parse(response)
    results = data["results"]
    return nil if results.blank?

    result = results.first
    { lat: result["latitude"], lon: result["longitude"], name: result["name"] }
  rescue JSON::ParserError
    nil
  end

  private

  def self.fetch_from_api(lat:, lon:)
    params = {
      latitude: lat,
      longitude: lon,
      current: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,uv_index",
      daily: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max",
      temperature_unit: "fahrenheit",
      wind_speed_unit: "mph",
      precipitation_unit: "inch",
      timezone: "auto",
      forecast_days: 7
    }

    query = params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v.to_s)}" }.join("&")
    url = URI("#{BASE_URL}?#{query}")
    response = http_get(url)
    return nil unless response

    data = JSON.parse(response)
    return nil unless data["current"] && data["daily"]

    current = data["current"]
    daily = data["daily"]

    {
      location_name: nil,
      current: {
        temperature: current["temperature_2m"],
        feels_like: current["apparent_temperature"],
        humidity: current["relative_humidity_2m"],
        precipitation: current["precipitation"],
        wind_speed: current["wind_speed_10m"],
        uv_index: current["uv_index"],
        weather_code: current["weather_code"],
        description: weather_description(current["weather_code"]),
        emoji: weather_emoji(current["weather_code"])
      },
      daily: daily["time"].each_with_index.map do |date_str, i|
        {
          date: Date.parse(date_str),
          high: daily["temperature_2m_max"][i],
          low: daily["temperature_2m_min"][i],
          precipitation: daily["precipitation_sum"][i],
          precipitation_probability: daily["precipitation_probability_max"][i],
          weather_code: daily["weather_code"][i],
          description: weather_description(daily["weather_code"][i]),
          emoji: weather_emoji(daily["weather_code"][i])
        }
      end
    }
  rescue JSON::ParserError
    nil
  end

  def self.http_get(url)
    uri = url.is_a?(URI) ? url : URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    response.body
  rescue Net::TimeoutError, SocketError, Errno::ECONNREFUSED
    nil
  end

  def self.weather_description(code)
    case code
    when 0 then "Clear sky"
    when 1 then "Mainly clear"
    when 2 then "Partly cloudy"
    when 3 then "Overcast"
    when 45, 48 then "Foggy"
    when 51, 53, 55 then "Drizzle"
    when 56, 57 then "Freezing drizzle"
    when 61, 63, 65 then "Rain"
    when 66, 67 then "Freezing rain"
    when 71, 73, 75 then "Snow"
    when 77 then "Snow grains"
    when 80, 81, 82 then "Rain showers"
    when 85, 86 then "Snow showers"
    when 95 then "Thunderstorm"
    when 96, 99 then "Thunderstorm with hail"
    else "Unknown"
    end
  end

  def self.weather_emoji(code)
    case code
    when 0 then "☀️"
    when 1 then "🌤️"
    when 2 then "⛅"
    when 3 then "☁️"
    when 45, 48 then "🌫️"
    when 51, 53, 55, 56, 57 then "🌦️"
    when 61, 63, 65, 66, 67 then "🌧️"
    when 71, 73, 75, 77 then "❄️"
    when 80, 81, 82 then "🌧️"
    when 85, 86 then "🌨️"
    when 95, 96, 99 then "⛈️"
    else "🌡️"
    end
  end
end
