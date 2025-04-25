class AddVolumeToWaterings < ActiveRecord::Migration[8.0]
  def change
    add_column :waterings, :volume, :float
    add_column :waterings, :units, :integer
  end
end
