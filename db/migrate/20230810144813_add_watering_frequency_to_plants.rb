class AddWateringFrequencyToPlants < ActiveRecord::Migration[7.0]
  def change
    add_column :plants, :watering_frequency, :integer
  end
end
