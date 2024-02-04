class AddManualWateringFrequency < ActiveRecord::Migration[7.0]
  def change
    add_column :plants, :manual_watering_frequency, :boolean
  end
end
