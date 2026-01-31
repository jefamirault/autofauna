class AddShareEnabledToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :share_enabled, :boolean, default: false

    reversible do |dir|
      dir.up do
        Plant.where.not(share_token: nil).update_all(share_enabled: true)
      end
    end
  end
end
