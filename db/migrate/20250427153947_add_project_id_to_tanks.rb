class AddProjectIdToTanks < ActiveRecord::Migration[8.0]
  def change
    add_column :tanks, :project_id, :integer
  end
end
