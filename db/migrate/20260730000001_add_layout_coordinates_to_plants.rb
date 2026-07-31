class AddLayoutCoordinatesToPlants < ActiveRecord::Migration[8.0]
  # Position of a plant's chip on its location's diagram, stored normalized 0.0–1.0
  # rather than pixels so the canvas can be responsive. NULL = not placed yet.
  def change
    add_column :plants, :layout_x, :float
    add_column :plants, :layout_y, :float
  end
end
