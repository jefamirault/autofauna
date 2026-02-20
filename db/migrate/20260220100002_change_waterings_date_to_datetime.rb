class ChangeWateringsDateToDatetime < ActiveRecord::Migration[8.0]
  def up
    change_column :waterings, :date, :datetime
    rename_column :waterings, :date, :watered_at
  end

  def down
    rename_column :waterings, :watered_at, :date
    change_column :waterings, :date, :date
  end
end
