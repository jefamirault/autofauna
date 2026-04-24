class AddWaterChangeScheduleToTanks < ActiveRecord::Migration[8.0]
  def change
    add_column :tanks, :water_change_min_days, :integer
    add_column :tanks, :water_change_max_days, :integer
  end
end
