class ChangeLogEntriesUserIdNullifyOnDelete < ActiveRecord::Migration[8.0]
  def change
    change_column_null :log_entries, :user_id, true
    remove_foreign_key :log_entries, :users
    add_foreign_key :log_entries, :users, on_delete: :nullify
  end
end
