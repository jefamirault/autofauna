class AddSnoozedUntilToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :snoozed_until, :datetime
  end
end
