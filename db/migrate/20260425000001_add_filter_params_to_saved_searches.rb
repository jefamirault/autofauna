class AddFilterParamsToSavedSearches < ActiveRecord::Migration[8.0]
  def change
    add_column :saved_searches, :filter_params, :text
  end
end
