class AddRemainingVolumeToRecipeBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_batches, :remaining_volume, :float
    add_column :recipe_batches, :last_adjusted_at, :datetime
  end
end
