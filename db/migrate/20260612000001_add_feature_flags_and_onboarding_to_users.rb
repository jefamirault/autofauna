class AddFeatureFlagsAndOnboardingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :track_waterings,      :boolean, default: true, null: false
    add_column :users, :use_fertilizers,      :boolean, default: true, null: false
    add_column :users, :precise_measurements, :boolean, default: true, null: false
    add_column :users, :track_soil_moisture,  :boolean, default: true, null: false
    add_column :users, :has_aquarium,         :boolean, default: true, null: false
    add_column :users, :onboarding_completed_at, :datetime
  end
end
