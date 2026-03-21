class WeatherLocation < ApplicationRecord
  belongs_to :user

  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :name, length: { maximum: 100 }

  scope :primary, -> { where(primary: true) }

  def display_name
    name.presence || location_name.presence || "#{latitude}, #{longitude}"
  end

  def make_primary!
    transaction do
      user.weather_locations.where(primary: true).update_all(primary: false)
      update!(primary: true)
    end
  end
end
