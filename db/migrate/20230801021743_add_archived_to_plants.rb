class AddArchivedToPlants < ActiveRecord::Migration[7.0]
  def change
    add_column :plants, :archived, :boolean, default: false
  end
end
