class AddColorToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :color, :string, default: '#0E487B'
  end
end
