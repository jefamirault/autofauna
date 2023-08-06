class AddIntervalToWaterings < ActiveRecord::Migration[7.0]
  def change
    add_column :waterings, :interval, :integer
  end
end
