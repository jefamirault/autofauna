class ChangeWateringDateToDatetime < ActiveRecord::Migration[7.0]
  def change
    change_column :waterings, :date, :datetime
  end
end
