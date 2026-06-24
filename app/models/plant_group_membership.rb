class PlantGroupMembership < ApplicationRecord
  belongs_to :plant
  belongs_to :plant_group
end
