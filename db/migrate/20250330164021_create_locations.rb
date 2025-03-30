class CreateLocations < ActiveRecord::Migration[8.0]
  def up
    create_table :locations do |t|
      t.integer :zone_id
      t.string :name
      t.text :description

      t.timestamps
    end

    # Add a reference column to plants table
    add_reference :plants, :location, foreign_key: true

    # Temporarily store all unique location strings
    location_names = Plant.pluck(:location).uniq.compact.reject(&:empty?)

    # Create Location records for each unique location name
    location_mapping = {}
    location_names.each do |name|
      location = Location.create!(name: name, zone: Zone.first)
      location_mapping[name] = location.id
    end

    # Update each plant with the appropriate location_id
    Plant.all.each do |plant|
      location_id = location_mapping[plant.read_attribute :location]
      plant.update_column(:location_id, location_id)
    end
    # Remove the old location column
    remove_column :plants, :location
  end

  def down
    # Add the location string column back
    add_column :plants, :location, :string

    # Copy data back from the association
    Plant.find_each do |plant|
      if plant.location_id.present?
        location_name = Location.find(plant.location_id).name
        plant.update_column(:location, location_name)
      end
    end

    # Remove the location reference
    remove_reference :plants, :location, foreign_key: true

    drop_table :locations
  end

end
