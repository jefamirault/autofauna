class ChangeWateringDatetimeToDate < ActiveRecord::Migration[7.0]
  def change
    change_column :waterings, :date, :date
  end
end
