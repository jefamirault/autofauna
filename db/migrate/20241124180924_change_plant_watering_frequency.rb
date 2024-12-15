class ChangePlantWateringFrequency < ActiveRecord::Migration[7.1]
  def up
    add_column :plants, :min_watering_freq, :integer
    add_column :plants, :max_watering_freq, :integer

    Plant.all.each do |plant|
      freq = plant.watering_frequency
      if freq.nil?
        plant.min_watering_freq = nil
        plant.max_watering_freq = nil
      else
        plant.min_watering_freq = freq - 1
        plant.max_watering_freq = freq + 1
      end
      plant.save
    end
    remove_column :plants, :watering_frequency
    remove_column :plants, :manual_watering_frequency
  end
  def down
    add_column :plants, :watering_frequency, :integer
    add_column :plants, :manual_watering_frequency, :boolean

    Plant.all.each do |plant|
      if plant.min_watering_freq
        plant.watering_frequency = plant.min_watering_freq + 1
      else
        plant.watering_frequency = nil
      end
      plant.save
    end
    remove_column :plants, :min_watering_freq
    remove_column :plants, :max_watering_freq
  end
end
