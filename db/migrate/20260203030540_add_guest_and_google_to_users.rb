class AddGuestAndGoogleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :guest, :boolean, default: false, null: false
    add_column :users, :google_uid, :string
    add_column :users, :avatar_url, :string
    add_index :users, :google_uid, unique: true
  end
end
