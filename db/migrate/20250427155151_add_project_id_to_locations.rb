class AddProjectIdToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :project_id, :integer
  end
end
